# 02_aspath

`r1` currently prefers the path via `r2`. Prepend `r2`'s AS number on its
**outbound** UPDATE so `r1` switches to `r3` (whose AS_PATH is shorter).

## How to fix

Open a second terminal and log into `r2` (`make debug`, or `docker exec`):

- On `r2` add a route-map and apply it outbound to `r1`:
  `docker exec <r2> vtysh -c 'conf t' -c 'route-map PAD_65002 permit 10' -c 'set as-path prepend 65002 65002' -c 'router bgp 65002' -c 'neighbor 10.1.12.1 route-map PAD_65002 out'`
- The new attributes are sent on the next UPDATE, so reset the session:
  `docker exec <r2> vtysh -c 'clear bgp *'`

Press Enter to verify; `f` re-injects the fault.
