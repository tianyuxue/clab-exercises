# VLAN and Trunk

## Scenario

A small office runs one switch: twenty-four machines on one subnet, all in the
same group. Then a noisy test lab joins the same switch, its broadcasts reach
every machine, and the network slows down.

## Terms

- **Broadcast domain**: the set of ports a broadcast reaches; a switch floods a broadcast — and a frame whose destination MAC it has not learned (unknown-unicast) — to every port in the domain except the one it arrived on.
- **VLAN**: a logical broadcast domain; two ports in different VLANs never see each other's broadcasts.
- **802.1Q tag**: a 4-byte field inserted between the source MAC and the EtherType; it carries a 12-bit VLAN ID.
- **PVID**: the VLAN a port assigns to frames that arrive without a tag.
- **Access port**: a port that puts one VLAN on one cable, untagged.
- **Trunk port**: a port that carries several VLANs between devices, tagged.
- **Native VLAN**: the one VLAN on a trunk whose frames travel untagged.

## Why it hurts

A flat network is a single broadcast domain, so every broadcast and unknown-unicast
frame floods to every device, the noisy lab included. The switch has no knob to keep
groups apart while they share hardware.

## Why the naive fix fails

Buying a second switch and linking it just extends the same broadcast domain, so the
problem returns; a second link for redundancy only creates a Layer-2 loop.

## The mechanism

A switch only sees bytes, so it must decide which broadcast domain each frame belongs
to. The three rules follow from where that decision has to happen.

**Why access ports are untagged, with a PVID.** A plain host NIC does not speak
802.1Q by default: it neither adds nor strips tags, and it would drop a tagged frame
as an unknown EtherType. So on a host link the switch keeps frames untagged. But then
the switch must still place a bare frame into a VLAN — that is the port's PVID. This
link carries one VLAN, so a tag would carry no information anyway.

**Why trunks tag.** One cable between two switches must carry several VLANs. If the
frames were untagged, the far switch could not tell VLAN 10 from VLAN 20, and
isolation would collapse. So a trunk tags each frame with its 802.1Q VLAN ID (except
the native VLAN's, introduced next): on a shared link the tag is the frame's only
identity.

**Why native VLAN exists.** Some devices and links do not tag. To let them use a
trunk, one VLAN is designated native: its frames travel untagged, as if the trunk
were an access port for that VLAN. The price is that an untagged frame has no
identity of its own — the receiving port's PVID is the only thing that assigns its
VLAN. If the two ends disagree, the same frame lands in different VLANs and fails
silently.

## Configure and inspect

```sh
ip link add br0 type bridge vlan_filtering 1 && ip link set br0 up
ip link set eth1 master br0 && ip link set eth2 master br0 && ip link set eth3 master br0

bridge vlan add dev eth1 vid 10 pvid untagged      # access: one VLAN, untagged
bridge vlan add dev eth3 vid 10                    # trunk: VLAN 10 tagged
bridge vlan add dev eth3 vid 20 pvid untagged      # trunk native VLAN 20

bridge vlan show                                    # PVID and egress tagging per port
```

On the wire, an access link shows no tag; a trunk shows `vlan 10` for the tagged
VLAN-10 traffic (the native VLAN still crosses untagged):
```sh
tcpdump -i eth1 -e -nn     # access: no "vlan"
tcpdump -i eth3 -e -nn     # trunk: "vlan 10" on the tagged VLAN-10 frames
```

## Common questions

- Same subnet but no connectivity? The two access ports' PVIDs differ; a host's untagged frames land in different VLANs even on one subnet.
- Same VLAN across two switches but no connectivity? The trunk is not a member of that VLAN, so frames are dropped.
- Native VLAN mismatch? Untagged frames are placed by the receiving PVID; a mismatch moves them to another VLAN, silently.
- Can a host sit on a trunk? Yes, if it tags its own frames with a VLAN subinterface and uses a VLAN the trunk carries.
