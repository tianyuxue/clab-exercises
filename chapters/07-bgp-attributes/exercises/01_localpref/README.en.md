# 01_localpref

`r1` learns `10.2.2.0/24` from both `r2` and `r3`, and currently prefers the path
via `r3`. Make it prefer the path via `r2` using LOCAL_PREF.

## How to fix

Open a second terminal and log into `r1` (`make debug`, or `docker exec`):

- Check the current choice: `docker exec <r1> ip route get 10.2.2.100`
- Set LOCAL_PREF on routes learned from `r2`:
  `docker exec <r1> vtysh -c 'conf t' -c 'route-map FROM_R2 permit 10' -c 'set local-preference 200' -c 'router bgp 65001' -c 'neighbor 10.1.12.2 route-map FROM_R2 in'`

LOCAL_PREF takes effect immediately for the RIB. Press Enter to verify; `f` re-injects the fault.
