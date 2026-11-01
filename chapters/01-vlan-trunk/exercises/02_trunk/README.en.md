# 02_trunk

`h1` (on `sw1`) and `h3` (on `sw2`) are both VLAN 10 but cannot reach each other
across the trunk.

## Cause

One inter-switch link carries several VLANs. Without a tag, the far switch cannot
tell VLAN 10 from VLAN 20, so isolation breaks. A trunk therefore tags frames with
their 802.1Q VLAN ID and forwards only the VLANs it allows.

## Observe

Capture on `sw1`'s trunk port (`eth3`) while `h1` pings `h3`. After the fix, VLAN 10
frames show `vlan 10`; access ports (`eth1` / `eth2`) still show untagged frames.

## Fix

Allow VLAN 10 on the trunk at both switches:

```sh
docker exec <sw1> bridge vlan add dev eth3 vid 10
docker exec <sw2> bridge vlan add dev eth1 vid 10
```

Press Enter to verify; `f` re-injects the fault.
