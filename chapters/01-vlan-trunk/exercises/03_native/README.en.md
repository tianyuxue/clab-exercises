# 03_native

VLAN 20 is the trunk's **native VLAN**. `h2` (sw1) and `h4` (sw2) are both in
VLAN 20 but cannot reach each other.

## Why

A trunk designates one VLAN whose frames travel **untagged**, so devices/links
that do not tag still work. But an untagged frame carries no VLAN identity: the
receiving port's **PVID** is the only thing that decides which VLAN it belongs
to. If the two ends disagree, the same untagged frame is placed in different
VLANs — and it fails silently, with no error.

## Observe it

In clab-tui, capture on the trunk (sw1 eth3) while `h2` pings `h4`. VLAN-20
frames show **no tag**, while VLAN-10 frames still show `vlan 10`.

## Fix

Make VLAN 20 native on both ends:
`docker exec <sw2> bridge vlan add dev eth1 vid 20 pvid untagged`

Press Enter to verify; `f` re-injects the fault.
