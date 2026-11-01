# 03_native

VLAN 20 is the trunk's **native VLAN**. `h2` (sw1) and `h4` (sw2) are both VLAN 20
but cannot reach each other.

## Cause

Native VLAN frames cross the trunk **untagged** for compatibility with devices and
links that do not tag. An untagged frame carries no VLAN identity, so the receiving
port classifies it by its local **PVID**. If the two ends disagree, the frame lands
in a different VLAN and is silently dropped.

## Observe

Capture on the trunk (`sw1 eth3`) while `h2` pings `h4`. VLAN 20 frames are
**untagged**; VLAN 10 traffic, if present, still shows `vlan 10`.

## Fix

`sw1` is already correct; make VLAN 20 native on `sw2`'s trunk as well:

```sh
docker exec <sw2> bridge vlan add dev eth1 vid 20 pvid untagged
```

Press Enter to verify; `f` re-injects the fault.
