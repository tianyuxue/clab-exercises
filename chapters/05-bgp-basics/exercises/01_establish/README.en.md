# 01_establish

`r1` (AS 65001, 10.1.12.1/30) and `r2` (AS 65002, 10.1.12.2/30) should form an
eBGP session, but `r2` rejects `r1`'s OPEN: the neighbor's `remote-as` is wrong.

## How to fix

Open a second terminal and log into the running routers (`make debug`, or `docker exec`):

- `docker exec -it <r1> vtysh -c 'show bgp summary'` (and the same on `<r2>`)
- On `r2` set the neighbor's remote-as to match `r1`'s AS:
  `docker exec <r2> vtysh -c 'conf t' -c 'router bgp 65002' -c 'neighbor 10.1.12.1 remote-as 65001'`

The change applies immediately. Press Enter to verify; `f` (fast reset) re-injects the fault.
