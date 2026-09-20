# MLAG and EVPN multi-homing

## Scenario

A server is cabled to **two** switches so it survives one switch failing: one
cable to `sw1`, another to `sw2`. Each switch is independent. The server also runs
LACP, expecting a single bundle across both cables.

## Terms

- **MLAG** (multi-chassis LAG; Cisco vPC; MC-LAG): a technique that makes two
  independent switches act as **one** LACP partner towards the server.
- **peer-link**: the link between the two MLAG switches that carries L2 traffic
  between them and lets them keep a consistent view of the bundle.
- **orphan port**: a port on one peer that is single-homed (not part of the MLAG);
  it reaches the other peer only through the peer-link.
- **split-brain**: the failure mode where the peer-link breaks but both peers keep
  forwarding, each believing it owns the LAG.
- **EVPN**: a BGP address family that carries L2/L3 reachability (MAC/IP) and
  multi-homing information.
- **EVPN multi-homing (EVPN-MH)**: the open-standard alternative to vendor MLAG:
  the two switches coordinate the access links with BGP EVPN instead of a
  peer-link.
- **ESI** (Ethernet Segment Identifier): the shared name the two switches give the
  same access segment, so the network knows they multi-home it together.
- **Designated Forwarder (DF)**: among the switches of an ES, the one elected to
  flood broadcast/unknown/multicast (BUM) traffic for a given VLAN.
- **all-active / single-active**: whether all switches of an ES forward at once
  (all-active) or only one does at a time (single-active).
- **stacking**: fusing several switches into one device with a single control
  plane and a single management/failure domain.

## Why it hurts

Dual-homing to two independent switches breaks the two things the server expects:

1. Its **LACP** now talks to two different partners (two System IDs), so it cannot
   form one bundle across both cables.
2. The two uplinks form a **Layer-2 loop** between the switches, which STP removes
   by blocking one uplink — so one of your two cables carries no traffic.

## Why the naive fix fails

- **Let STP block one uplink**: the server is now effectively single-homed again;
  the blocked cable is wasted, and failover takes seconds.
- **Stack the two switches**: this does make them one LACP partner, but it also
  merges them into a single control plane and a single failure domain — one bad
  software upgrade or one supervisor failure takes down the whole stack.

## The mechanism

Both MLAG and EVPN-MH keep the switches as **two independent control planes** while
making them look like one partner to the server:

- **MLAG**: a **peer-link** carries L2 traffic between the peers, and a control
  protocol keeps their view of the bundle in sync. The server's LACP sees one
  System ID and forms one bundle across both cables. A failure of the peer-link
  while both uplinks stay up is dangerous — each peer may think it owns the LAG
  (**split-brain**) — so production MLAG adds a keepalive and a primary/secondary
  role as a tie-breaker.
- **EVPN-MH**: the two switches attach the access links to a shared **ESI**, and
  advertise it with **BGP EVPN**. A **Designated Forwarder** election decides who
  floods BUM traffic, so the access links can all forward at once (**all-active**)
  with no peer-link and no blocked half. This is the modern, open-standard way to
  replace vendor MLAG.

## Configure and inspect

There is no lab in this chapter; the inspection commands to remember are:

- on a Linux/SR Linux switch, `show lag` shows the bundle and its members;
- on an EVPN-MH switch, the Ethernet Segment and its ESI are visible in the EVPN
  state (SR Linux: under `network-instance … protocols bgp-evpn ethernet-segments`).

## Common questions

- **Peer-link failure = split-brain**: without a keepalive and a primary/secondary
  role, both peers can accept the LAG and black-hole traffic.
- **Orphan ports**: a single-homed port on one peer depends on the peer-link to
  reach the other peer; losing the peer-link isolates it.
- **Stacking is not free**: it removes the two-control-plane benefit — one failure
  domain and a bigger blast radius.
- **EVPN-MH needs a control plane**: ESI/BGP EVPN must be configured on both
  switches; without it they still act as two unrelated LACP partners.
