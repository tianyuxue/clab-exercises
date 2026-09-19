# Link aggregation (LACP)

## Why

Redundant links without STP are a loop; with STP, every redundant link but one
is **blocked**, so you pay for bandwidth you cannot use. Link aggregation gets
both: several physical links are bundled into one logical link that carries
traffic in parallel, and survives a member failure.

## What

A **LAG** (link aggregation group, a.k.a. PortChannel/bond) is a logical
interface made of several members. The switch hashes each flow onto one member, so
a single flow still cannot exceed one link, but many flows share the bundle.
**LACP** (IEEE 802.1AX) negotiates the bundle with the peer so both sides agree
which links are members and that they are healthy.

## How

- Members reference the LAG by id (`aggregate-id`); the LAG is a routed interface
  (`lag1`) with subinterfaces and IP addresses.
- **LACP mode**: at least one side must be **ACTIVE** to send LACPDUs. **PASSIVE**
  only responds. Two PASSIVE sides never negotiate.
- **admin-key** (and system id/priority) must be consistent for members to join;
  `min-links` keeps the LAG down unless enough members are up.
- SR Linux: `sr_cli` configures it; `show lag` reports aggregate state, member
  state and `oper-down-reason`; ping over the LAG uses the default
  network-instance.

## Reading

Read how LACP frames negotiate membership. Then answer: why can two PASSIVE
interfaces never form a bundle, and what does min-links protect against?
