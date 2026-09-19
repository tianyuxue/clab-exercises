# VLAN and Trunk

## Why

A switch floods unknown unicast, broadcast and multicast frames to every port in
the same **broadcast domain**. As a flat network grows, that domain grows with
it: more noise, more attack surface, and no way to keep teams or tenants apart
without buying more switches. You need to cut one physical network into several
logical ones.

## What

A **VLAN** is a logical broadcast domain. Ports in different VLANs behave as if
they were on separate switches, even when they share the same physical links.
This is what lets one access switch serve many isolated segments.

## How

- **802.1Q tag**: a 4-byte field inserted between the source MAC and the
  EtherType. It carries a 12-bit **VID** (0–4095) and a 3-bit **PCP** priority.
- **Access port**: carries a single VLAN, frames leave untagged. The port's
  **PVID** decides which VLAN incoming untagged frames belong to.
- **Trunk port**: carries many VLANs; frames are tagged. A **native VLAN**
  handles untagged traffic on the trunk (both ends must agree).
- **Linux bridge VLAN filtering**: `bridge vlan add dev ethX vid N pvid untagged`
  sets an access port; adding several VIDs makes it a trunk.

## Reading

Read the tag layout and the access/trunk distinction. Then answer: if two hosts
share the same subnet but sit on ports with different PVIDs, why does ARP never
get through?
