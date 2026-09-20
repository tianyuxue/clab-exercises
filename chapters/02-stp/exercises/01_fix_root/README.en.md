# 01_fix_root

The triangle `sw1-sw2-sw3` has a layer-2 loop that STP breaks by blocking one
port. Today `sw2` has bridge priority 4096 and wins the root election; the core
switch `sw1` must be the root instead.

## How to fix

Inspect the STP state and tune the running `sw1` directly:

- `docker exec <sw1> cat /sys/class/net/br0/bridge/{bridge_id,root_id,priority}`
- `docker exec <sw1> bridge -j link show`
- give `sw1` a lower priority than sw2's 4096 (0 is valid), e.g.
  `docker exec <sw1> ip link set dev br0 type bridge priority 0`

The change takes effect immediately; press Enter to verify. Keep STP enabled —
the loop must be removed by blocking a port, not by deleting a link. `f` (fast
reset) re-injects the fault if you want to start over.
