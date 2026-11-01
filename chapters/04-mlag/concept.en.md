# MLAG and EVPN Multi-Homing: Two Switches, One Partner

## The scene

A server has two NICs, one to `sw1` and one to `sw2`. The switches are independent. The cabling is for redundancy: lose one switch, keep running. This is dual-homing. The server runs an LACP bond and expects both cables to form one logical link. Instead the bond does not come up, or only one member forwards.

## Where it breaks

LACP partners identify themselves with a System ID. The server expects one; `sw1` and `sw2` each present their own, so no single bundle forms.

Without LACP, the two uplinks plus the server form a Layer-2 loop, and STP blocks one uplink. Stacking fixes the LACP view but merges both switches into one control plane and one failure domain, so one bad upgrade or supervisor failure takes down both.

## Terms

- **MLAG** (multi-chassis LAG; Cisco vPC; MC-LAG): makes two independent switches look like one LACP partner. The server-side bundle is a LAG, and the two switches are peers.
- **peer-link**: the direct link between peers. It carries L2 traffic and keeps their bundle view in sync.
- **orphan port**: a single-homed port on one peer; it reaches the other peer only through the peer-link.
- **split-brain**: the peer-link fails while both peers keep forwarding and each believes it owns the LAG.
- **EVPN**: a BGP address family carrying L2/L3 reachability (MAC/IP) and multi-homing information.
- **EVPN-MH**: the open-standard replacement for vendor MLAG, using BGP EVPN instead of a peer-link.
- **ESI** (Ethernet Segment Identifier): a shared name for one access segment (an ES), telling the network that both switches multi-home it.
- **Designated Forwarder (DF)**: the switch elected per VLAN to flood broadcast, unknown unicast, and multicast (BUM) traffic for an ES.
- **all-active / single-active**: whether every switch in the ES forwards at once, or only one.
- **stacking**: fusing switches into one device with one control plane and failure domain.

## How MLAG works

The peers stay independent but present one System ID to the server. The peer-link carries L2 traffic between them, and a control protocol keeps the bundle view aligned, so the server forms one bundle across both cables.

If the peer-link fails while both uplinks stay up, both peers may accept the LAG with no path to each other. Production MLAG adds a keepalive and a primary/secondary role to break the tie. An orphan port also depends on the peer-link.

## How EVPN-MH works

Both switches attach the access links to the same ESI and advertise it with BGP EVPN. A DF election picks one switch per VLAN for BUM traffic, so all links can forward at once (all-active). There is no peer-link and no STP-blocked half.

## Inspect

There is no lab in this chapter.

- `show lag` on a Linux or SR Linux switch shows the bundle and its members.
- On an EVPN-MH switch, the Ethernet Segment and ESI appear in EVPN state (SR Linux: under `network-instance … protocols bgp-evpn ethernet-segments`).

## Common pitfalls

- **Peer-link failure**: without keepalive and roles, both peers can accept the LAG and black-hole traffic.
- **Orphan ports**: losing the peer-link isolates a single-homed port.
- **Stacking has a cost**: one control plane means one failure domain and a larger blast radius.
- **EVPN-MH needs both sides**: ESI and BGP EVPN on each switch, or they remain unrelated LACP partners.
