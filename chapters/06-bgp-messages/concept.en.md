# BGP messages — UPDATE and NOTIFICATION

## Scenario

Two operators already have a working BGP session. Now they need the routes to
actually flow across it, and a way to understand what goes wrong when they do
not.

## Terms

- **Message header**: the fixed 19-octet prefix of every message: a 16-octet marker (all ones), a 2-octet length (including the header), and a 1-octet type.
- **OPEN**: type 1; the first message, which negotiates session parameters.
- **UPDATE**: type 2; carries withdrawn routes, path attributes, and NLRI (the advertised prefixes).
- **NOTIFICATION**: type 3; reports an error and closes the session.
- **KEEPALIVE**: type 4; a bare header confirming the session is alive.
- **NLRI (Network Layer Reachability Information)**: the list of prefixes an UPDATE advertises.
- **Path attribute**: a typed, flagged field in an UPDATE, e.g. ORIGIN, AS_PATH, NEXT_HOP.
- **AS_PATH**: the ordered list of ASes a route has traversed.
- **Route-map**: FRR's policy construct; an outbound route-map can filter or modify attributes such as AS_PATH.

## Why it hurts

When a prefix does not appear on the peer, the operator is blind without the
message format: is the session down, is a policy blocking it, or is the route
malformed?

## Why the naive fix fails

Restarting the routers or re-adding the `network` statement does not help when
the real cause is that no route was ever sent. You must look at what the session
is doing (policy status) and, if needed, at the bytes on the wire.

## The mechanism

After the session is Established, UPDATE messages carry routes. Each UPDATE is
prefixed by the message header and holds path attributes such as AS_PATH:

```
Marker(16, all ones) | Length(2) | Type(1)          <- header
Withdrawn Routes Length(2) | Withdrawn Routes | Total Path Attribute Length(2) | Path Attributes | NLRI
```

FRR requires a policy for eBGP by default (`ebgp-requires-policy`); without one
the session is up but `pfxSnt` stays 0. FRR sends a NOTIFICATION `Cease` (code 6)
on a deliberate reset (`clear bgp *`).

## Configure and inspect

On r1:
```
vtysh -c 'show bgp summary'
vtysh -c 'show bgp ipv4 unicast'
```

On the sniffer, capture and then read the messages on the wire:
```
tcpdump -i any -w /tmp/bgp.pcap tcp port 179
tshark -r /tmp/bgp.pcap -Y 'bgp.type==2' -T fields -e bgp.update.path_attribute.type_code
tshark -r /tmp/bgp.pcap -Y 'bgp.type==2' -T fields -e bgp.update.path_attribute.as_path_segment.as4 -e bgp.nlri_prefix
tshark -r /tmp/bgp.pcap -Y 'bgp.type==3' -T fields -e bgp.notify.major_error
```

## Common questions

- The neighbor is Established but sends no prefixes. Why? FRR's `ebgp-requires-policy` is on (the neighbor shows `peerState` `Policy`); add `no bgp ebgp-requires-policy` or an outbound route-map, then `clear bgp *`.
- Where is the prefix in the UPDATE? In the NLRI field (`bgp.nlri_prefix`); AS_PATH is a path attribute (`...as_path_segment.as4`).
- Why does `clear bgp *` produce a NOTIFICATION? FRR sends `Cease` (code 6) on a deliberate reset before closing.
