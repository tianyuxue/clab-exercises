# 04_tagged_host

`h4` tags its own frames through a VLAN subinterface and connects to `sw2`'s trunk
port, but cannot reach `h1`.

## Cause

A trunk port can face any 802.1Q-capable device, including a server or hypervisor
with a VLAN subinterface. The device tags its own frames, but its VLAN ID must be in
the trunk's allowed list; otherwise the switch drops the frames.

## Observe

Capture on the trunk (`sw1 eth3`) while `h1` pings `h4`. After the fix, `h4`'s frames
show `vlan 10`; in the faulty state `h4` uses VLAN 30 and its frames never reach the
trunk.

## Fix

Move `h4`'s subinterface to VLAN 10:

```sh
docker exec <h4> ip link del eth1.30
docker exec <h4> ip link add link eth1 name eth1.10 type vlan id 10
docker exec <h4> ip addr add 10.0.10.4/24 dev eth1.10
docker exec <h4> ip link set eth1.10 up
```

Press Enter to verify; `f` re-injects the fault.
