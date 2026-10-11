# BGP troubleshooting

## Scenario

A BGP session that used to work is down, or a route is missing. The operator has
minutes to find the cause among several that look similar.

## Terms

- **iBGP**: a BGP session between two routers in the same AS.
- **eBGP**: a BGP session between two routers in different ASes.
- **FSM**: the fixed set of states a BGP session moves through (see chapter 05).
- **OpenSent**: the FSM state after the TCP connection is up and this side has sent its OPEN.
- **Active**: the FSM state where the router keeps (re)attempting to reach the peer; typically the TCP connection is not completing, e.g. a wrong neighbor address or no route to it.
- **Bad Peer AS**: an OPEN Message Error (code 2, subcode 2) sent when the peer's AS number is not the one configured.
- **NEXT_HOP**: the address an UPDATE tells the receiver to forward through; iBGP keeps the eBGP next-hop unless rewritten.
- **next-hop-self**: an iBGP setting that rewrites NEXT_HOP to the advertising router's own address.
- **NOTIFICATION**: the message that reports an error and closes the session.

## Why it hurts

"Sessions are down" and "routes are missing" are not diagnoses. Each maps to a
different state or attribute, and the fix for one does nothing for another.

## Why the naive fix fails

Clearing the session or rebooting does not help if the neighbor address, the
remote AS, or the next-hop reachability is wrong; the same failure returns.

## The mechanism

Read the FSM state first: stuck `Active` typically means the peer is unreachable
(address or routing); reaching `OpenSent` then resetting with a NOTIFICATION
`Bad Peer AS` means the remote AS does not match. A route that is learned but not
installed is usually an unresolvable `NEXT_HOP`, often fixed with
`next-hop-self` on the iBGP edge (or by making the next-hop reachable).

## Configure and inspect

On a router:
```
vtysh -c 'show bgp summary'
vtysh -c 'show bgp ipv4 unicast'
```

On the sniffer, read a NOTIFICATION:
```
tshark -r /tmp/bgp.pcap -Y 'bgp.type==3' -T fields -e bgp.notify.major_error -e bgp.notify.minor_error_open
```

## Common questions

- The neighbor sits in Active. What do you check first? The neighbor address and whether there is a route to it.
- The peer resets right after OpenSent. Why? Its remote-as does not match our AS; look for NOTIFICATION Bad Peer AS.
- An iBGP route is learned but not installed. Why? Its NEXT_HOP is unreachable; set `next-hop-self` on the edge router.
