# BGP troubleshooting: read the state before fixing

## Scene

`edge` peers with `ext` over eBGP and with `core` over iBGP. `ext` announces
`192.0.2.0/24`, which `edge` should pass to `core`.

Three failures appear in this lab:

- `edge`'s eBGP neighbor stays in Active.
- The session reaches OpenSent, then NOTIFICATION resets it.
- `core` sees the prefix in its BGP table but not in its routing table.

Clearing the session or rebooting repeats the same input.

## Terms

- **iBGP / eBGP**: BGP within one AS / between ASes. `edge`-`core` is iBGP (65001);
  `edge`-`ext` is eBGP (65001/65002).
- **FSM / OPEN**: Idle, Connect, Active, OpenSent, OpenConfirm, Established. OPEN is
  the first message, sent after TCP is up. **Active** means TCP 179 is not up;
  **OpenSent** means the local OPEN has been sent.
- **UPDATE / NEXT_HOP**: an UPDATE carries prefixes; NEXT_HOP is the address used to
  reach them and must resolve. **next-hop-self** rewrites it to the advertising
  iBGP router's address.
- **NOTIFICATION / Bad Peer AS**: an error report that closes the session; Bad Peer
  AS is OPEN Message Error 2/2, an AS mismatch against `remote-as`.

## Three failures

**Active.** `edge` is `10.1.12.1/30`, `ext` is `10.1.12.2/30`, but `edge` configures
neighbor `10.1.12.9`. That address is off-link, so TCP never opens. Check the
neighbor address and the route to it.

**OpenSent, then Bad Peer AS.** `ext` expects `remote-as 65099`; `edge` is AS 65001.
`ext` rejects the OPEN with NOTIFICATION 2/2 and closes the session. Capture TCP
179, read the major/minor codes, then align both AS numbers.

**Established, no installed route.** `edge` learns `192.0.2.0/24` from `ext` with
NEXT_HOP `10.1.12.2`, and iBGP keeps that next hop toward `core`. `core` only has
`10.1.1.0/30` connected, so the path is invalid. Use `next-hop-self` on `edge`'s
iBGP neighbor, or make the next hop reachable.

## Inspect

```sh
vtysh -c 'show bgp summary'
vtysh -c 'show bgp ipv4 unicast'
```

`show bgp summary` gives neighbor state and prefix count; `show bgp ipv4 unicast`
shows paths, NEXT_HOP, and validity.

```sh
tshark -r /tmp/bgp.pcap -Y 'bgp.type==3' -T fields -e bgp.notify.major_error -e bgp.notify.minor_error_open
```

Major 2, minor 2 means OPEN Message Error / Bad Peer AS.

## Triage order

1. Check neighbor state. Active: check address and route. OpenSent and reset: read
   NOTIFICATION.
2. For a rejected OPEN, compare both `remote-as` values.
3. For a learned but uninstalled route, check NEXT_HOP; use `next-hop-self` or add
   a route to the next hop.
4. Fix the configuration, then run `clear bgp *`; resetting first repeats the
   failure.
