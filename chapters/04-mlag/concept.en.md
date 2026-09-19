# MLAG and EVPN multi-homing

## Why

A server single-homed to one switch dies with that switch. The obvious fix —
connect it to **two** switches — breaks two assumptions at once:

- The server's LACP bond now talks to **two different LACP partners**, so it
  cannot form one bundle (and can flap or black-hole).
- The two uplinks create a **layer-2 loop** that must be blocked, so half the
  bandwidth is wasted again.

You want redundancy, active/active bandwidth, and no STP blocking.

## What

**MLAG** (multi-chassis LAG, Cisco vPC, MC-LAG) makes two switches look like
**one** LACP partner to the server. They are joined by a **peer-link** that
carries L2 traffic between them and a control protocol that keeps their view of
the LAG in sync. **EVPN multi-homing (EVPN-MH)** achieves the same with an open
standard: both leaves attach the access links to a shared **Ethernet Segment
Identifier (ESI)**, and BGP EVPN advertises the segment so the two switches
coordinate forwarding.

## How

- **Peer-link**: carries L2 between the MLAG peers; if it fails while the uplinks
  stay up, both peers may think they own the LAG — **split-brain**. Production
  MLAG adds a keepalive and a primary/secondary role to break the tie.
- **Orphan ports**: single-homed ports on one peer; they need the peer-link to
  reach the other peer.
- **EVPN-MH**: each leaf advertises an **Ethernet Auto-Discovery (A-D) / ES
  route**; a **Designated Forwarder** election decides who floods BUM traffic, so
  no peer-link is needed for forwarding and there is no blocked half.
- **Stacking** (StackWise/VSS): fuses switches into one control plane with a
  single management and failure domain — simple, but proprietary and a bigger
  blast radius. MLAG/EVPN-MH keep two independent control planes.

## Reading

Read how EVPN advertises an Ethernet Segment. Then answer: what replaces the
peer-link's role, and why is an all-active design better than blocking one uplink?
