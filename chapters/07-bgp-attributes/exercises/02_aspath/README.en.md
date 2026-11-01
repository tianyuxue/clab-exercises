# 02_aspath

`r1` learns `10.2.2.0/24` from `r2` and `r3`, and currently uses `r2`. Make it use `r3`.

## Cause

The baseline ties on the early attributes and `r2` wins on router-id. AS_PATH is compared at step 4, and shorter wins. `r3` advertises a one-AS path (`65003`); prepending `65002` on `r2`'s outbound UPDATE lengthens its path so `r1` switches.

## Observe

```sh
docker exec <r1> ip route get 10.2.2.100
```

The next hop is `10.1.12.2` (`r2`). Now read the AS_PATHs:

```sh
docker exec <r1> vtysh -c 'show bgp ipv4 unicast'
```

Before the fix, the path via `r2` shows `65002` and the one via `r3` shows `65003`. Equal length, so router-id still decides.

## Fix

Prepend on `r2` outbound:

```sh
docker exec <r2> vtysh -c 'conf t' -c 'route-map PAD_65002 permit 10' -c 'set as-path prepend 65002 65002' -c 'router bgp 65002' -c 'neighbor 10.1.12.1 route-map PAD_65002 out'
```

The new attribute goes out on the next UPDATE, so reset the session:

```sh
docker exec <r2> vtysh -c 'clear bgp *'
```

`r1` should now use `10.1.13.2`. Press Enter to verify; `f` re-injects the fault.
