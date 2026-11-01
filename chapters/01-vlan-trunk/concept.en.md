# VLAN and Trunk Essentials

## Overview

A small office shares one Layer-2 switch. All hosts sit in one broadcast domain, so a
new high-broadcast test platform floods every port and degrades the whole network.
VLANs provide logical isolation on shared hardware. Adding a second switch only
enlarges the same broadcast domain; adding a redundant link without STP creates a
Layer-2 loop.

## Key terms

- **Broadcast domain**: the set of ports reached by a broadcast or unknown unicast.
- **VLAN**: a logical broadcast domain; ports in different VLANs do not see each
  other's broadcasts.
- **802.1Q tag**: a 4-byte field between the source MAC and EtherType, carrying a
  12-bit VLAN ID.
- **PVID**: the VLAN assigned to untagged frames entering a port.
- **Access port**: one VLAN per port, frames leave untagged.
- **Trunk port**: multiple VLANs over one link, frames leave tagged.
- **Native VLAN**: the one VLAN on a trunk that travels untagged.

## How it works

A switch must decide which broadcast domain every frame belongs to.

- An **access port** faces a host NIC that does not understand 802.1Q. Incoming
  untagged frames get the port's PVID; outgoing frames are untagged.
- A **trunk port** carries several VLANs between switches. Frames are tagged with
  their VLAN ID so the far end can tell VLAN 10 from VLAN 20.
- The **native VLAN** is sent untagged for compatibility. The receiving port's PVID
  assigns it, so both ends must agree; otherwise traffic lands in the wrong VLAN or
  is silently dropped.

## Configure and verify

```sh
# create a VLAN-filtering Linux bridge
ip link add br0 type bridge vlan_filtering 1 && ip link set br0 up
ip link set eth1 master br0 && ip link set eth2 master br0 && ip link set eth3 master br0

# eth1: access port in VLAN 10, untagged
bridge vlan add dev eth1 vid 10 pvid untagged

# eth3: trunk carrying VLAN 10 tagged; VLAN 20 is the untagged native VLAN
bridge vlan add dev eth3 vid 10
bridge vlan add dev eth3 vid 20 pvid untagged

# show VLAN membership, PVIDs, and egress tagging
bridge vlan show
```

```sh
# access link: plain Ethernet frames, no 802.1Q header
tcpdump -i eth1 -e -nn

# trunk: VLAN 10 frames show "vlan 10"; native VLAN 20 stays untagged
tcpdump -i eth3 -e -nn
```

## Troubleshooting

- **Same subnet, no connectivity**: access ports use different PVIDs, so untagged
  host frames enter different VLANs.
- **Same VLAN across switches, no connectivity**: the trunk does not allow that
  VLAN, so frames are dropped.
- **Native VLAN mismatch**: the receiving PVID decides the VLAN; a mismatch creates
  a silent one-way leak into the wrong VLAN.
- **Host on a trunk**: valid if the host tags its own frames through a VLAN
  subinterface and uses a VLAN the trunk allows.
