# Write a minimal BGP speaker in C

## Scenario

You want to see exactly how little a peer must implement to exchange routes with
a real router. Rather than trust a library, you write the bytes yourself.

## Terms

- **Message header**: 16 octets of marker (all ones), a 2-octet length (including the header), and a 1-octet type.
- **OPEN**: the first message; here version 4, my AS, hold time, and BGP identifier.
- **KEEPALIVE**: a bare 19-octet header that keeps the session alive.
- **UPDATE**: withdrawn routes, path attributes (ORIGIN, AS_PATH, NEXT_HOP), then NLRI.
- **FSM (finite state machine)**: the states your program walks: after OPEN and KEEPALIVE, Established.

## Why it hurts

Reading about the format is not the same as emitting bytes another stack accepts:
field order, byte order, and length accounting must all be exact.

## Why the naive fix fails

Sending an OPEN without reading the peer's OPEN, or omitting KEEPALIVEs, leaves
the session stuck or lets the Hold Timer expire; the peer tears it down.

## The mechanism

BGP runs over TCP port 179. You send an OPEN, receive the peer's OPEN, exchange
KEEPALIVEs, and the session is Established. An UPDATE then carries NLRI with its
path attributes:

```
Marker(16) | Length(2) | Type(1) | Withdrawn Routes Length(2) | Path Attributes | NLRI
```

All multi-octet fields are in network byte order.

## Configure and inspect

On r1:
```
vtysh -c 'show bgp summary'
vtysh -c 'show bgp ipv4 unicast'
```

Your program's output is on the speaker node:
```
cat /tmp/bgp.log
```

## Common questions

- Why must the marker be all ones? The header is fixed-size; the marker is defined as all ones so the length field can locate the next message.
- Does Length include the header? Yes, it counts the whole message; KEEPALIVE is 19.
- Why send KEEPALIVE every hold/3? The negotiated Hold Time expires if nothing arrives; a third of it is the recommended margin.
