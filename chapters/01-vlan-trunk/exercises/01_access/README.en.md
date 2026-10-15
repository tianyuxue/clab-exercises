# 01_access

`h1` and `h2` sit in the same subnet on `sw1`, but cannot reach each other.

## Why

A host NIC does not understand 802.1Q, so it sends untagged frames. A switch
must decide which broadcast domain those untagged frames belong to — it uses the
port's **PVID**. If the two access ports disagree, the hosts end up in different
VLANs and never see each other's ARP, even on the same subnet.

## Observe it

In clab-tui, capture on `sw1`'s port facing `h1` (eth1). You will see **no VLAN
tag** — the switch keeps the host link untagged.

## Fix

- `docker exec <sw1> bridge vlan show` — compare the PVID of eth1 and eth2.
- Move eth2 from VLAN 20 to VLAN 10:
  `docker exec <sw1> bridge vlan del dev eth2 vid 20`
  `docker exec <sw1> bridge vlan add dev eth2 vid 10 pvid untagged`

Press Enter to verify; `f` re-injects the fault.
