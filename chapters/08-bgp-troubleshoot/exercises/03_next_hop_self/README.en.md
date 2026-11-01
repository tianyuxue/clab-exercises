# 03_next_hop_self

## Task

Make `core` install `192.0.2.0/24` learned from `edge`.

## Cause

`edge` advertises the eBGP route over iBGP and keeps NEXT_HOP `10.1.12.2`. `core`
has no route to that address, so the BGP path is invalid and not installed.

## Observe

```sh
docker exec <core> vtysh -c 'show bgp ipv4 unicast 192.0.2.0/24'
```

NEXT_HOP is `10.1.12.2` and the path is marked inaccessible.

## Fix

On `edge`, enable `next-hop-self` for the iBGP neighbor, then clear the session:

```sh
docker exec <edge> vtysh -c 'conf t' -c 'router bgp 65001' -c 'neighbor 10.1.1.2 next-hop-self' -c 'end' -c 'clear bgp *'
```

Press Enter to verify; `f` re-injects the fault.
