# 01_access

`h1` and `h2` share a subnet on `sw1` but cannot ping each other.

## Cause

Host NICs send untagged frames. The switch assigns each incoming frame to a VLAN by
the port's **PVID**. If the two access ports use different PVIDs, the hosts land in
different VLANs and cannot resolve each other's ARP, even on the same subnet.

## Observe

Capture on `sw1`'s `eth1` (towards `h1`) in clab-tui: frames carry **no VLAN tag**.
The switch keeps host links untagged and classifies frames internally.

## Fix

- Compare the PVIDs with `docker exec <sw1> bridge vlan show`.
- Move `eth2` from VLAN 20 to VLAN 10:

  ```sh
  docker exec <sw1> bridge vlan del dev eth2 vid 20
  docker exec <sw1> bridge vlan add dev eth2 vid 10 pvid untagged
  ```

Press Enter to verify; `f` re-injects the fault.
