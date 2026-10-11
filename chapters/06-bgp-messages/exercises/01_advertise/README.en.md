# 01_advertise

`r1` (AS 65001, 10.1.12.1/30) and `r2` (AS 65002, 10.1.12.2/30) are established,
and `r1` has `network 192.0.2.0/24`, yet `r2` never receives the prefix.

## How to fix

Open a second terminal and log into the running routers (`make debug`, or `docker exec`):

- `docker exec -it <r1> vtysh -c 'show bgp summary'` — the neighbor shows `peerState "Policy"` and `pfxSnt 0`.
- FRR requires a policy for eBGP by default. Allow it on `r1`:
  `docker exec <r1> vtysh -c 'conf t' -c 'router bgp 65001' -c 'no bgp ebgp-requires-policy'`
- The UPDATE is only sent on a new session, so reset it:
  `docker exec <r1> vtysh -c 'clear bgp *'`

Press Enter to verify; `f` re-injects the fault.
