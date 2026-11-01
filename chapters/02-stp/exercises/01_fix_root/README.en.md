# 01_fix_root

`sw1`, `sw2` and `sw3` form a triangle. STP already blocks one port, so `h1` can
ping `h2`, but the root bridge is `sw2`.

## Cause

`sw2` uses priority 4096 while `sw1` and `sw3` keep the default 32768, so `sw2`
wins the election on the lowest bridge ID. It is not the core switch: it sits at
the edge with less uplink capacity, and every tree recalculation now follows it.
`sw1` should be the root.

## Observe

```sh
docker exec <sw1> cat /sys/class/net/br0/bridge/{bridge_id,root_id,priority}
docker exec <sw1> bridge -j link show
```

On `sw1`, `root_id` differs from `bridge_id`, so it is not the root. On `sw2` the
two values match. `bridge -j link show` also shows which triangle port is blocked;
its link stays up and simply stops forwarding.

## Fix

Give `sw1` a lower priority than 4096 (`0` is valid):

```sh
docker exec <sw1> ip link set dev br0 type bridge priority 0
```

Wait for reconvergence, then press Enter to verify. Keep STP enabled: the loop is
removed by blocking a port, not by deleting a link. Press `f` to re-inject the
fault.
