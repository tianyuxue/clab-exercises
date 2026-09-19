# STP/RSTP

## Why

Ethernet has no TTL. If you add a second link for redundancy, a single broadcast
frame loops forever, is duplicated every lap, and within seconds the switches are
saturated — a broadcast storm. You need redundancy **and** a loop-free topology.

## What

**STP** (802.1D) builds a loop-free tree out of a meshed topology: it elects one
**root bridge**, then every other bridge keeps exactly one best path towards the
root and **blocks** its redundant ports. The blocked link stays physically up
and takes over if the active one fails. **RSTP** (802.1w) converges in
sub-seconds instead of tens of seconds.

## How

- **Bridge ID** = 16-bit **priority** + 6-byte MAC. The bridge with the **lowest**
  bridge ID becomes **root**. The default priority is 32768, so by default the
  lowest MAC wins — never leave this to chance.
- **Path cost** to the root decides the best port; lower cost wins, ties broken by
  lower neighbor bridge ID, then lower port ID.
- Port roles: **root port** (best path to root), **designated port** (best port on
  a segment), and **blocked/alternate** ports (kept as backup).
- The Linux bridge exposes this via `stp_state 1` and the per-bridge sysfs files
  `/sys/class/net/br0/bridge/{bridge_id,root_id,priority}`.

## Reading

Read how the root is elected and how a port ends up blocking. Then answer: if two
bridges have the same priority, what decides the root, and why is that a bad
thing to rely on in production?
