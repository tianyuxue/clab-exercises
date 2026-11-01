# Write a minimal BGP speaker in C

## The setup

FRR on `r1` shows a peer in `Established` and a few prefixes in
`show bgp ipv4 unicast`. Under all that machinery is a TCP connection carrying
fixed-layout bytes.

So: can a small C program connect to `r1:179`, be treated as AS 65001, reach
Established, and get one prefix (`192.0.2.0/24`) accepted? That is the exercise.
You only need the part that handshakes and advertises a single route.

## Where it goes wrong

Connecting and writing "hello" gets you nothing. BGP peers each send an OPEN,
then each send a KEEPALIVE. Skip one, or misstate a length by two bytes, and the
peer stalls or resets without telling you which byte was wrong. The work is in
getting field order, big-endian encoding and length accounting right.

## Terms

- **Message header**: 19 bytes: 16-byte marker, 2-byte length, 1-byte type.
- **Marker**: 16 bytes of `0xFF`; a legacy synchronisation sentinel, still checked.
- **OPEN**: version, my AS, hold time, BGP identifier, optional parameters length.
- **KEEPALIVE**: header only; says "still here".
- **Hold Time**: the smaller of the two advertised values; silence past it
  kills the session.
- **UPDATE**: withdrawn routes, path attributes, NLRI.
- **NLRI**: the advertised prefix, e.g. `192.0.2.0/24`.
- **Path attribute**: ORIGIN, AS_PATH, NEXT_HOP metadata attached to the NLRI.
- **FSM / Established**: the state walk from Idle to the point where UPDATEs flow.

## The wire format

Length counts the whole message, header included, so KEEPALIVE carries 19. Types:
1 OPEN, 2 UPDATE, 3 NOTIFICATION, 4 KEEPALIVE.

The OPEN you send is 29 bytes:

```
offset  size  field
0       16    Marker (0xFF x16)
16      2     Length = 29
18      1     Type = 1
19      1     Version = 4
20      2     My AS = 65001
22      2     Hold Time = 90
24      4     BGP Identifier = 10.1.12.1
28      1     Optional Parameters Length = 0
```

KEEPALIVE is just the header: marker, length 19, type 4. Send one every hold/3
(30s here) or the peer expires the session.

UPDATE body:

```
Withdrawn Routes Length(2) | Withdrawn Routes | Total Path Attribute Length(2) | Path Attributes | NLRI
```

Nothing is withdrawn here, so both length fields are 0. Each attribute is
flags, type, length, value: ORIGIN = 0 (IGP), AS_PATH = one AS_SEQUENCE
containing 65001, NEXT_HOP = `10.1.12.1`. NLRI encodes as a mask-length byte followed by only the significant
prefix octets, so `192.0.2.0/24` is `0x18` plus `192 0 2`.

NEXT_HOP must be `10.1.12.1`, the speaker's on-link address. Anything else leaves
the route in the BGP table but unresolved in the kernel, so the ping assertion
fails while the route count looks right.

Handshake order: connect, send OPEN, read peer OPEN, send KEEPALIVE, receive
KEEPALIVE, then send UPDATE. Reading inbound messages after Established is
optional here; a full speaker would also validate types, honour the peer's hold
time, and send NOTIFICATION on error.

## Implement

`src/main.c` already has `tcp_connect`, `send_all`, `recv_message`, `put16` and
`put32`. Fill in `build_open`, `build_keepalive`, `build_update`, then wire up
`main`. All multi-byte fields are big-endian. Delete the `// I AM NOT DONE` line
when done. An assertion checks for that line first.

## Inspect

On `r1`:

```sh
vtysh -c 'show bgp summary'
vtysh -c 'show bgp ipv4 unicast'
```

Expect `Established`, one route for `192.0.2.0/24` via `10.1.12.1`, total 1.
Your program logs on the speaker node:

```sh
cat /tmp/bgp.log
```

To see bytes, capture port 179 on the speaker; `-X` prints hex. OPEN is 29 bytes
starting with sixteen `ff`; KEEPALIVE is 19.

```sh
tcpdump -i eth1 -nn -X port 179
```

## Common traps

- **Stuck in Active**: TCP never connected; check the process and the
  `10.1.12.0/30` addressing, and that `argv[1]` is `10.1.12.2`.
- **Drops after a few seconds**: missing KEEPALIVE, or a wrong type; the 90s hold
  timer fires.
- **Established but no route**: Total Path Attribute Length is off, so the peer
  drops the whole UPDATE.
- **Route present, ping fails**: NEXT_HOP is not `10.1.12.1`, or the route lacks
  `*` because the next hop is unreachable.
- **Route count is 2**: the assertion wants exactly one prefix.
- **Wrong marker**: still validated; Length is what frames messages.
- **No routes at all on a fresh setup**: FRR applies RFC 8212 and needs an inbound
  policy for eBGP. The topology sets `no bgp ebgp-requires-policy`.
