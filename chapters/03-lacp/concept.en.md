# Link aggregation with LACP

## The symptom

A server uplinks at 1 Gbit/s and saturates at peak. A second cable to the same
switch lights up but adds no bandwidth and triggers a loop alarm. After bundling
both links into `lag1` with LACP at both ends, `show lag` still reports `lag1`
down with `no-active-links`, though both ports are up.

## Why the obvious options fail

- Two cables without aggregation form a Layer-2 loop; STP blocks one, so
  throughput stays at 1 Gbit/s.
- A static bond comes up even when the far end is wrong, and a half-broken
  member keeps forwarding and dropping traffic.
- One cable per switch gives two independent LACP partners with different System
  IDs, so the host sees two one-link bundles. That needs MLAG or EVPN-MH.

## Terms

- **LAG** (bond, PortChannel): one logical interface over physical members;
  addresses and routes sit on the LAG.
- **Member**: a physical link referenced by the LAG.
- **Flow hashing**: header fields pick one member per flow, per direction.
- **LACP** (802.1AX): both ends exchange LACPDUs to agree which links belong to
  the bundle and whether they are healthy.
- **active / passive**: active sends LACPDUs, passive only replies; at least one
  side must be active.
- **admin-key**: members must agree on it to join the same bundle.
- **min-links**: minimum usable members for the LAG to stay up.

## Mechanism

The switch hashes source/destination MAC, IP, and ports, picks a member, and sends
the frame there. Aggregate bandwidth is the sum of the members across many flows;
one flow never exceeds one member.

LACP keeps the bundle honest: both ends send LACPDUs with System ID, port,
admin-key, and member state. A member joins only when both ends put it in the
LAG, the admin-keys match, the link is healthy, and min-links is met. A failed
member leaves and traffic rehashes onto the rest; if min-links is no longer met,
the LAG goes down on purpose instead of forwarding over a degraded bundle.

## Configure

Point the physical ports at the LAG, then configure the LAG itself; addresses go
on its subinterface.

```sh
# run on the switch: feed CLI commands to sr_cli
sr_cli -d <<'EOF'
enter candidate
set / interface ethernet-1/1 ethernet aggregate-id lag1
set / interface ethernet-1/2 ethernet aggregate-id lag1
set / interface lag1 lag lag-type lacp
set / interface lag1 lag lacp lacp-mode ACTIVE
set / interface lag1 subinterface 0 ipv4 address 10.0.0.1/30
set / network-instance default interface lag1.0
commit now
EOF
```

On the peer use `10.0.0.2/30`; `lacp-mode` can stay `PASSIVE`, since one active
side is enough.

## Verify

```sh
sr_cli -d "show lag"                       # is lag1 up? are members up? what is oper-down-reason?
sr_cli -d "ping -c 2 10.0.0.2 network-instance default"
```

Watch the `lag1` state, each member's `oper-state`, and `oper-down-reason`. The
usual causes here are `no-active-links` and `lacp-down`. A ping only proves the
data plane; check both.

## Traps

- **Both passive**: nobody sends LACPDUs, so make one side active.
- **admin-key mismatch**: members stay out with `lacp-down`; use the same key.
- **One flow, one member**: use several concurrent flows to fill the bundle.
- **min-links**: below the threshold the LAG goes down and routes withdraw, so
  traffic takes another path.
