# BGP basics — session establishment

## Scenario

Two networks run by different operators need to exchange routes. Each operator
manages its own devices; neither trusts the other's IGP. They agree to speak BGP
across a single point-to-point link.

## Terms

- **BGP (Border Gateway Protocol)**: the routing protocol that exchanges routes between ASes.
- **Autonomous System (AS)**: a network under one administration, identified by an AS number (e.g. 65001).
- **IGP (Interior Gateway Protocol)**: the routing protocol one operator runs inside its own network (e.g. OSPF); it is not exchanged between different ASes.
- **Peer (neighbor)**: the router at the other end of a BGP session.
- **eBGP**: a BGP session between two different ASes.
- **Finite State Machine (FSM)**: the fixed set of states a BGP session moves through, e.g. `Idle`, `Connect`, `Active`, `OpenSent`, `OpenConfirm`, `Established`.
- **OPEN**: the first BGP message, which negotiates parameters.
- **KEEPALIVE**: a periodic message that confirms the session is still alive.
- **NOTIFICATION**: an error message that reports a problem and closes the session.
- **Hold Time**: the maximum interval without a KEEPALIVE or UPDATE before the peer is declared dead; negotiated in the OPEN.
- **BGP Identifier**: the 4-octet value in the OPEN that identifies the sender, usually the router-id.
- **Capabilities (Optional Parameters)**: optional fields in the OPEN used to negotiate features such as address families.

## Why it hurts

Routers in different ASes do not share an IGP, so they cannot learn each other's
prefixes through it. Without a session there is no path, and the two networks
stay isolated.

## Why the naive fix fails

Pointing a static route at the neighbor works only for that one prefix and does
not scale or react to failures. BGP keeps the session alive with KEEPALIVEs and
tears it down when the peer goes away, which a static route cannot do.

## The mechanism

BGP runs over TCP port 179. The session walks the FSM: after TCP is up the local
router sends an OPEN; the peer answers with its OPEN; each side sends a KEEPALIVE
and the session becomes `Established`. A session with a mismatched remote AS is
rejected with a NOTIFICATION ("Bad Peer AS"). The OPEN carries:

```
Version=4 | My AS | Hold Time | BGP Identifier | Optional Parameters (capabilities)
```

## Configure and inspect

On r1:
```
vtysh -c 'show bgp summary'
vtysh -c 'show bgp summary json'
```

On the sniffer, observe the OPEN on the wire:
```
tcpdump -i any -w /tmp/bgp.pcap tcp port 179
tshark -r /tmp/bgp.pcap -Y 'bgp.type==1' -T fields -e bgp.open.myas -e bgp.open.holdtime -e bgp.open.identifier
```

## Common questions

- The neighbor never reaches `Established`. Which field do I check first? The expected `remote-as` must match the peer's actual AS; a mismatch raises "Bad Peer AS".
- Why must KEEPALIVEs be shorter than the Hold Time? Missing KEEPALIVEs for a whole Hold Time makes the peer declare the session dead (Hold Timer Expired).
- Why does a timer change need a reset? Timers are negotiated in the OPEN, so they apply to a new session.
- Two peers propose different Hold Times — which one is used? The negotiated value is the smaller of the two.
