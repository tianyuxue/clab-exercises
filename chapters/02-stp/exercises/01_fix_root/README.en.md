# 01_fix_root

The triangle `sw1-sw2-sw3` has a layer-2 loop that STP breaks by blocking one
port. Today `sw2` has bridge priority 4096 and wins the root election; the core
switch `sw1` must be the root instead.

## How to fix

Inspect the STP state, then edit `sw1/stp.sh` on the host and let watch reload it
into `sw1`:

- `docker exec <sw1> cat /sys/class/net/br0/bridge/{bridge_id,root_id,priority}`
- `docker exec <sw1> bridge -j link show`
- give `sw1` a lower priority than sw2's 4096 (0 is valid), remove `I AM NOT DONE`

Saving triggers reload; you can also press Enter to force verification. Keep STP
enabled — the loop must be removed by blocking a port, not by deleting a link.
