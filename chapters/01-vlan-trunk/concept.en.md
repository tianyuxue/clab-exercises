# VLAN and Trunk

## Scenario

A small office runs a single switch. Twenty-four computers plug into it, all on
the same IP subnet, `10.0.1.0/24`. When one machine sends an ARP request, every
other machine hears it — that is how a switch works, and at this size it is
perfectly fine.

Then the office adds a noisy test lab to the same switch. Its broadcast traffic
now reaches the office machines too, and the whole network starts to feel slow.

## Terms

- **Broadcast domain**: the set of ports a broadcast frame reaches. A switch
  floods a broadcast — and any frame whose destination MAC it has not learned —
  to every port in the same broadcast domain.
- **Flat network**: a network where all devices share one broadcast domain. When
  we say "the network grew", we always mean "the broadcast domain grew".
- **VLAN**: a *logical* broadcast domain. Two ports in different VLANs never see
  each other's broadcasts, even though they sit on the same physical switch.
- **802.1Q tag**: a 4-byte field a switch inserts between the source MAC and the
  EtherType. It carries a 12-bit **VLAN ID** (VID, 1–4094) and a 3-bit
  **priority** (PCP).
- **Access port**: a port that belongs to a single VLAN and sends frames
  untagged. Its **PVID** (port VLAN ID) is the VLAN that incoming untagged frames
  are dropped into.
- **Trunk port**: a port that carries several VLANs and sends frames tagged. Its
  **native VLAN** handles untagged frames on the trunk; both ends must agree on
  it.

## Why it hurts

A flat network has exactly one broadcast domain by definition, so every broadcast
and every unknown-unicast frame is flooded to all devices — the noisy lab
included. The switch offers no knob to keep two groups apart while they share the
same physical hardware.

## Why the naive fix fails

The obvious move is to buy a second switch and move the lab onto it. If the two
switches are connected, that link becomes part of the *same* broadcast domain, so
the problem comes right back. Adding a second link between the switches for
redundancy only makes it worse: the two links form a Layer-2 loop, and STP
resolves it by blocking one link — so you paid for a link you cannot use.

## The mechanism

A **VLAN** splits one physical switch into several independent broadcast domains.
Instead of isolating groups by buying hardware, you assign ports to VLANs:

- an **access port** puts a single VLAN on a single cable, untagged;
- a **trunk port** carries many VLANs between switches, tagged with the **802.1Q
  tag** so the far end knows which VLAN each frame belongs to.

Because the tag — not the cable — identifies the VLAN, one cable can carry many
logical networks, and the loop/blocking problem disappears: you separate groups
logically rather than physically.

On a real rack, this gives the two port types their familiar roles. An access
port is the **downlink** facing an end device — a server, workstation, or
printer; a trunk port is the **uplink** facing another network device — a switch,
AP, router, or hypervisor host. The names describe the port's role and the
direction of traffic, not a different kind of Ethernet; a server that tags its
own frames can sit on a trunk just as well.

## Configure and inspect

On a Linux bridge, VLAN filtering must be enabled on the bridge before per-port
VLANs mean anything:

```sh
ip link add br0 type bridge vlan_filtering 1 && ip link set br0 up
ip link set eth1 master br0 && ip link set eth2 master br0

# access ports: one VLAN, untagged
bridge vlan add dev eth1 vid 10 pvid untagged
bridge vlan add dev eth2 vid 10 pvid untagged

# a trunk port: several VLANs, tagged
bridge vlan add dev eth3 vid 10
bridge vlan add dev eth3 vid 20

bridge vlan show          # inspect PVID and egress tagging per port
```

## Common questions

- **Same subnet, different PVID**: two hosts can share an IP subnet yet sit on
  access ports with different PVIDs; the VLAN isolates their ARP, so they cannot
  reach each other. This is the fault the lab injects.
- **Native VLAN mismatch**: if a trunk's native VLAN differs at the two ends,
  untagged frames land in different VLANs and fail silently.
- **PVID is per port**: changing it moves *all* untagged traffic on that port, not
  just one host.
