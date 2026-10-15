# 02_trunk

`h1` (on sw1) and `h3` (on sw2) are both VLAN 10, but cannot reach each other.

## Why

One cable between two switches must carry several VLANs. If frames were not
tagged, the far switch could not tell VLAN 10 from VLAN 20 — isolation would
collapse. So a **trunk** tags each frame with its 802.1Q VLAN ID, and the switch
only forwards a VLAN across the link if the trunk is a member of it.

## Observe it

In clab-tui, capture on `sw1`'s trunk port (eth3) while `h3` is pinged. The
frames now show `vlan 10`. Compare with the access ports (eth1/eth2): no tag.

## Fix

- Add VLAN 10 to the trunk on both switches:
  `docker exec <sw1> bridge vlan add dev eth3 vid 10`
  `docker exec <sw2> bridge vlan add dev eth1 vid 10`

Press Enter to verify; `f` re-injects the fault.
