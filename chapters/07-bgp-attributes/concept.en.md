# BGP path selection: why this path and not the other

## The symptom

r1 learns 10.2.2.0/24 from two upstreams. Both paths work, yet traffic keeps taking the slower, more expensive one. Lowering MED on the other path changes nothing.

BGP is not random. It compares attributes in a fixed order and installs exactly one best path.

## Terms

- **Path attribute**: metadata carried with each BGP route; the input to the comparison.
- **Best path**: the route installed and advertised after the comparison.
- **Weight**: Cisco/FRR local value, highest wins, never sent to peers.
- **LOCAL_PREF**: preference inside this AS, highest wins, carried only in iBGP.
- **iBGP**: a session between routers in the same AS.
- **eBGP**: a session between routers in different ASes.
- **AS_PATH**: the AS numbers a route traverses; shorter wins.
- **AS_PATH prepending**: repeating your AS number outbound to make the path look longer.
- **MED**: a hint to a neighboring AS about the preferred entry point; lower wins, optional and non-transitive.
- **ORIGIN**: how the route entered BGP (IGP, EGP, incomplete); a tie-breaker.
- **Locally originated**: a route this router injects itself, such as with a network statement; preferred early.

ORIGIN, AS_PATH, and NEXT_HOP are well-known mandatory: an UPDATE carrying NLRI (route prefixes) must include them. MED is optional non-transitive. LOCAL_PREF stays inside the AS, so eBGP peers never see it.

## Comparison order

FRR/Cisco check the following, stopping at the first difference:

1. Weight, higher wins
2. LOCAL_PREF, higher wins
3. Locally originated
4. AS_PATH length, shorter wins
5. ORIGIN, IGP over EGP over incomplete
6. MED, lower wins
7. eBGP over iBGP
8. IGP metric to the next hop, lower wins
9. Router-id and other tie-breakers

MED is compared only between paths from the same neighbor AS by default. Paths from AS65002 and AS65003 are not compared on MED; `bgp always-compare-med` changes that.

In this lab both paths have a one-AS AS_PATH, ORIGIN IGP, MED 0, eBGP, and the same IGP metric. The decision falls through to router-id: the lower value wins.

## Steering traffic

Raise LOCAL_PREF inbound to prefer a neighbor. It applies to the local routing table (RIB) immediately:

```sh
vtysh -c 'conf t' -c 'route-map FROM_R2 permit 10' -c 'set local-preference 200' -c 'router bgp 65001' -c 'neighbor 10.1.12.2 route-map FROM_R2 in'
```

Lengthen AS_PATH outbound to make a neighbor less attractive:

```sh
vtysh -c 'conf t' -c 'route-map PAD_65002 permit 10' -c 'set as-path prepend 65002 65002' -c 'router bgp 65002' -c 'neighbor 10.1.12.1 route-map PAD_65002 out'
vtysh -c 'clear bgp *'
```

Prepending only reaches the peer on the next UPDATE, so reset the session if you do not want to wait.

## Inspect

```sh
ip route get 10.2.2.100
vtysh -c 'show bgp ipv4 unicast'
```

The first command shows the forwarding next hop (10.1.12.2 or 10.1.13.2). The second shows both paths, their attributes, and the best marker.

## Pitfalls

- **Lower MED does nothing across ASes.** MED is compared only within one neighbor AS.
- **The peer cannot see LOCAL_PREF.** It is not sent over eBGP.
- **Prepending seems ignored.** Wait for the next UPDATE or run `clear bgp *`.
- **An apparently tied path wins.** Router-id breaks the tie; the lower value wins.
- **Weight disappears on another router.** It is local and never advertised.
