# 01_advertise

`r1` (AS 65001) and `r2` (AS 65002) are established, and `r1` has
`network 192.0.2.0/24`, yet `r2` never receives the prefix.

## How to fix

- On `r1` run `docker exec <r1> vtysh -c 'show bgp summary'`; the peer shows
  `State/PfxRcd` in the `Policy` column with `pfxSnt 0`.
- FRR requires a policy for eBGP by default. Allow it:
  `docker exec <r1> vtysh -c 'conf t' -c 'router bgp 65001' -c 'no bgp ebgp-requires-policy'`

The change applies immediately. Press Enter to verify; `f` re-injects the fault.
