# BGP Messages: UPDATE and NOTIFICATION

## The session is up, but the route is missing

r1 (AS 65001) and r2 (AS 65002) have an Established eBGP session, yet r2 never learns
192.0.2.0/24 even though r1 configures `network 192.0.2.0/24`. `show bgp summary`
shows `pfxSnt 0`. A working session proves only that TCP 179 and OPEN succeeded; it
does not prove that any route was sent.

Troubleshoot in order: is the neighbor Established, does the local BGP table hold
the prefix, and does an UPDATE on the wire actually carry it?

## Terms

- **Message header**: 19 octets on every message. A 16-octet all-ones marker, a
  2-octet length that includes the header, and a 1-octet type. Length ranges from
  19 to 4096.
- **OPEN** (1): negotiates version, AS number, and Hold Time.
- **UPDATE** (2): carries withdrawn routes, path attributes, and NLRI.
- **NOTIFICATION** (3): reports an error code and closes the session.
- **KEEPALIVE** (4): header only, 19 octets; confirms the peer is alive.
- **NLRI**: the prefixes an UPDATE advertises.
- **Path attribute**: typed, flagged fields such as ORIGIN, AS_PATH, and NEXT_HOP.
- **AS_PATH**: the ordered list of ASes a route traversed; each AS appends its
  number.
- **Route-map**: FRR's policy construct; an outbound map modifies or filters what
  is sent.

## UPDATE layout

```
Marker(16, all ones) | Length(2) | Type(1)          <- header
Withdrawn Routes Length(2) | Withdrawn Routes | Total Path Attribute Length(2) | Path Attributes | NLRI
```

Read the header first, skip the withdrawn routes by their length field, take the
path attributes by their total length, and the remaining bytes are NLRI. The prefix
lives in NLRI, not in the header or AS_PATH.

## Why an Established peer sends nothing

FRR enables `ebgp-requires-policy` for eBGP by default. Without a policy it
advertises nothing. OPEN and KEEPALIVE still work, so the session reaches
Established, but `peerState` shows `Policy` and `pfxSnt` stays 0.

Drop the requirement with `no bgp ebgp-requires-policy`, or attach an outbound
route-map. Then run `clear bgp *`: existing UPDATEs are not resent just because the
configuration changed.

## NOTIFICATION on a deliberate reset

FRR sends NOTIFICATION Cease (code 6) before closing a session reset by
`clear bgp *`, so a code 6 capture is expected, not a fault. Codes 1 to 5 cover
header, OPEN, UPDATE, Hold Timer, and FSM errors.

## Observe

On r1:

```sh
vtysh -c 'show bgp summary'
vtysh -c 'show bgp ipv4 unicast'
```

On the sniffer:

```sh
tcpdump -i any -w /tmp/bgp.pcap tcp port 179
tshark -r /tmp/bgp.pcap -Y 'bgp.type==2' -T fields -e bgp.update.path_attribute.type_code
tshark -r /tmp/bgp.pcap -Y 'bgp.type==2' -T fields -e bgp.update.path_attribute.as_path_segment.as4 -e bgp.nlri_prefix
tshark -r /tmp/bgp.pcap -Y 'bgp.type==3' -T fields -e bgp.notify.major_error
```

The first command shows peer state and prefixes sent; the second shows the local BGP
table. The tshark filters decode UPDATE attribute types, AS_PATH with NLRI, and the
NOTIFICATION error code.

## Common pitfalls

- **Established but no prefix**: check for `peerState` `Policy`; add a policy or
  disable `ebgp-requires-policy`, then `clear bgp *`.
- **Route-map changed but the capture is stale**: UPDATEs are resent only after a
  session reset.
- **Wrong AS_PATH count**: r1 writes its own AS once and prepends twice, so the peer
  sees three 65001s. Prepend affects outbound attributes only.
- **NOTIFICATION read as a failure**: code 6 is an administrative Cease; check codes
  1 to 5 and which side sent it.
