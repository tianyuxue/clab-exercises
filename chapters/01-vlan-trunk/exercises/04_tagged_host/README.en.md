# 04_tagged_host

`h4` tags its own frames (a VLAN subinterface) and plugs into a trunk port on
`sw2`, but cannot reach `h1`.

## Why

A trunk port does not require the other end to be a switch. Any device that
speaks 802.1Q — a server or hypervisor host with a VLAN subinterface — can sit
on a trunk and send frames that already carry the tag. What matters is that the
device's VLAN ID is a VLAN the trunk carries; otherwise the switch drops it.

## Observe it

In clab-tui, capture on the trunk (sw1 eth3) while `h1` pings `h4`. The frames
already show `vlan 10`, emitted by the host itself.

## Fix

Set `h4`'s subinterface to VLAN 10:
`docker exec <h4> ip link del eth1.30; docker exec <h4> ip link add link eth1 name eth1.10 type vlan id 10`
then add its address and bring it up (see `h4/h4.sh`).

Press Enter to verify; `f` re-injects the fault.
