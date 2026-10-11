# Link aggregation (LACP)

## Scenario

A server needs more bandwidth than one 1 Gbit/s link can give, and it must keep
running when a cable or switch port fails. Its OS can bundle several links into
one with LACP. You run two cables from the server to a switch and configure a
bundle at both ends.

## Terms

- **LAG** (link aggregation group, also PortChannel or bond): one *logical*
  interface built from several physical **member** links.
- **Member**: a physical link that belongs to a LAG.
- **Flow hashing**: for each traffic flow, the switch hashes header fields to pick
  one member. A flow therefore uses one member (per direction).
- **LACP** (802.1AX): the protocol the two ends use to agree on which links are
  members and whether they are healthy.
- **Active / passive**: an **active** participant sends LACP frames (`LACPDUs`);
  a **passive** one only replies. At least one side must be active.
- **admin-key**: an identifier that members must agree on to join the same LAG.
- **min-links**: the minimum number of up members needed for the LAG to stay up.

## Why it hurts

A single link gives neither redundancy nor more than its own speed. Adding a
second link *without* aggregation makes STP block it, so you still use only one.
And if you connect the server's two links to **two independent switches**, its
LACP now faces two different partners and cannot form one bundle at all.

## Why the naive fix fails

- **Static bond (no LACP)**: the link comes up even when the far end is
  misconfigured, and a half-broken member keeps carrying — and dropping —
  traffic, because nothing negotiates health.
- **Two independent switches**: each switch is a separate LACP partner with its
  own System ID, so the server sees two one-link bundles instead of one two-link
  bundle. Making this work takes MLAG/EVPN-MH (next chapter).

## The mechanism

A **LAG** presents the member links as one logical interface, so a single IP
configuration and route cover all of them. Flow hashing spreads traffic across
the members, delivering aggregate bandwidth and resilience to member failure.

**LACP** keeps the bundle honest: both ends exchange LACP frames listing the
members they consider part of the bundle and their state. A member joins only when
both ends agree (same LAG, compatible **admin-key**) and the link is healthy. If a
member fails, it leaves the bundle and traffic rehashes onto the remaining members
— as long as **min-links** is still satisfied.

## Configure and inspect

On SR Linux, configure the LAG (members reference it by id; the LAG is a routed
interface) and inspect it with `show lag`:

```sh
# as a shell script on the switch: pipe CLI commands into sr_cli
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

sr_cli -d "show lag"                       # lag up? members up? oper-down-reason?
sr_cli -d "ping -c 2 10.0.0.2 network-instance default"
```

The key output is `show lag`: whether `lag1` is **up**, each member's
`oper-state`, and the `oper-down-reason` when it is not.

## Common questions

- **Both sides passive**: neither end sends LACP frames, so the bundle stays down
  with reason `no-active-links` — this is the fault the lab injects.
- **admin-key mismatch**: members stay out of the bundle with reason `lacp-down`.
- **One flow, one member**: a single flow never exceeds one member's speed;
  aggregation helps many flows, not one.
- **min-links**: if too few members are up, the LAG is intentionally kept down to
  avoid a degraded bundle.
