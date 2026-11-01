# BGP basics: how an eBGP session comes up

## Symptom

Two operators share a point-to-point link: r1 in AS 65001 and r2 in AS 65002. Addresses and neighbor commands look right, but `show bgp summary` stays on Active instead of Established. With no session there is no UPDATE, so neither side learns the other's prefixes.

## Why static routes fail

A static route can point at 10.1.12.2 for one prefix. It cannot track thousands of prefixes that appear and disappear, and it cannot withdraw when the peer dies. BGP first builds a TCP session, treats the far end as a peer, and exchanges routes only while the session lives. When the session drops, the routes learned from it go with it.

## Terms

- **BGP**: the protocol that exchanges routes between ASes.
- **AS (Autonomous System)**: one administered network, identified by a number such as 65001.
- **IGP**: a routing protocol run inside one operator's network, for example OSPF; it does not cross AS boundaries.
- **Peer**: the router at the other end of a BGP session.
- **eBGP**: a session between two different ASes.
- **FSM**: the fixed states `Idle`, `Connect`, `Active`, `OpenSent`, `OpenConfirm`, `Established`.
- **OPEN**: the first BGP message, used to negotiate parameters.
- **KEEPALIVE**: a periodic liveness message.
- **NOTIFICATION**: an error message that closes the session.
- **UPDATE**: the message that carries routes; prefixes travel in NLRI.
- **Hold Time**: how long the peer may stay silent before it is declared dead; negotiated in the OPEN.
- **BGP Identifier**: a 4-byte sender identity, usually the router-id.
- **Capabilities**: optional OPEN parameters, such as address families.

## The state machine

BGP runs over TCP 179. `Idle` waits for a Start event. `Connect` opens TCP. `Active` waits passively for the peer and retries on the ConnectRetry timer. `OpenSent` waits for the peer's OPEN. `OpenConfirm` waits for its KEEPALIVE. Only then does the session reach `Established` and allow UPDATEs.

`Active` is the most misread state: it does not mean the session works. The session is still stuck before TCP completes. Check reachability and TCP 179 first, then the neighbor configuration.

A peer whose AS does not match the configured remote-as sends NOTIFICATION "Bad Peer AS" and closes TCP. The local side retries and is rejected again.

## What the OPEN carries

```
Version=4 | My AS | Hold Time | BGP Identifier | Optional Parameters (capabilities)
```

My AS identifies the sender's AS; Hold Time proposes the keepalive window; BGP Identifier is a 4-byte identity; Optional Parameters carry Capabilities such as address families.

Hold Time is negotiated as the smaller of the two proposals: 180 and 9 become 9. A value of 0 disables keepalives. RFC 4271 suggests a KEEPALIVE interval of one third of Hold Time. Timers are fixed when the session is built, so a change needs a reset.

## Inspect it

On r1:

```sh
vtysh -c 'show bgp summary'
vtysh -c 'show bgp summary json'
```

The State/PfxRcd column shows a prefix count after `Established`; `Active` or `Connect` means the session is not up.

On the sniffer:

```sh
tcpdump -i any -w /tmp/bgp.pcap tcp port 179
tshark -r /tmp/bgp.pcap -Y 'bgp.type==1' -T fields -e bgp.open.myas -e bgp.open.holdtime -e bgp.open.identifier
```

With default timers r1's OPEN yields `65001 180 10.1.12.1`. After setting timers 3/9 and resetting the session, the same fields read `65001 9 10.1.12.1`.

## Common pitfalls

- **Stuck in Active**: check reachability and TCP 179, then remote-as and the update source.
- **"Bad Peer AS"**: the peer's My AS does not match your remote-as; fix your side.
- **KEEPALIVE longer than Hold Time**: the peer dies after one Hold Time and sends Hold Timer Expired (code 4), returning the session to Idle.
- **Timer change has no effect**: timers apply only to a new session; reset with `clear bgp *`.
- **Different Hold Times**: the minimum wins.
- **Session up, no routes**: FRR requires eBGP policy by default. This lab disables that check with `no bgp ebgp-requires-policy`; use route-maps in production.
