# 01_stuck_active

`edge` has an eBGP neighbor that never leaves Active, so no session forms.

## How to fix

Open a second terminal and log into `edge` (`make debug`, or `docker exec`):

- `docker exec <edge> vtysh -c 'show bgp summary'` — the neighbor is in the Active/Connect column.
- Compare the configured neighbor address with the link subnet (`10.1.12.0/30`).
  Remove the wrong one and add `10.1.12.2`:
  `docker exec <edge> vtysh -c 'conf t' -c 'router bgp 65001' -c 'no neighbor 10.1.12.9 remote-as 65002' -c 'neighbor 10.1.12.2 remote-as 65002' -c 'clear bgp *'`

Press Enter to verify; `f` re-injects the fault.
