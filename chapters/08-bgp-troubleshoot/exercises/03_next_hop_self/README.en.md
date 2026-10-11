# 03_next_hop_self

`core` learned `192.0.2.0/24` from `edge` over iBGP, but did not install it: the
NEXT_HOP is the external peer's address, which `core` cannot reach.

## How to fix

Open a second terminal and log into the routers (`make debug`, or `docker exec`):

- On `core`: `docker exec <core> vtysh -c 'show bgp ipv4 unicast 192.0.2.0/24'` —
  the path is not valid because NEXT_HOP is unreachable.
- On `edge`, make the iBGP advertisement use `edge`'s own address:
  `docker exec <edge> vtysh -c 'conf t' -c 'router bgp 65001' -c 'neighbor 10.1.1.2 next-hop-self' -c 'end' -c 'clear bgp *'`

Press Enter to verify; `f` re-injects the fault.
