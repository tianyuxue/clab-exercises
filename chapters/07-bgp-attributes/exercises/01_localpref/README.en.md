# 01_localpref

`r1` learns `10.2.2.0/24` from both `r2` and `r3`, and currently uses `r3`. Make it use `r2`.

## Cause

Both paths tie on AS_PATH length (one AS), ORIGIN (IGP), MED (0), eBGP, and IGP metric. The decision falls to router-id, and `r3` has the lower value. LOCAL_PREF is compared before AS_PATH, so a higher value on routes from `r2` flips the choice.

## Observe

Check the current next hop:

```sh
docker exec <r1> ip route get 10.2.2.100
```

It points at `10.1.13.2` (`r3`). Now read the BGP table:

```sh
docker exec <r1> vtysh -c 'show bgp ipv4 unicast'
```

Under `10.2.2.0/24`, both paths are listed; the best one goes via `r3` with the default LOCAL_PREF of 100.

## Fix

Set LOCAL_PREF 200 inbound from `10.1.12.2`:

```sh
docker exec <r1> vtysh -c 'conf t' -c 'route-map FROM_R2 permit 10' -c 'set local-preference 200' -c 'router bgp 65001' -c 'neighbor 10.1.12.2 route-map FROM_R2 in'
```

It applies to the local routing table immediately, no session reset needed. `ip route get 10.2.2.100` should now show `10.1.12.2`.

Press Enter to verify; `f` re-injects the fault.
