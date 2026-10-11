# BGP attributes and best-path selection

## Scenario

One router learns the same prefix from two providers. Which path it uses is not
luck: BGP compares a fixed list of attributes, and an operator can set some of
them to steer traffic.

## Terms

- **Weight**: a Cisco/FRR-local value, checked first; never sent to peers.
- **LOCAL_PREF**: how much this AS prefers a route, sent only in iBGP.
- **MED (MULTI_EXIT_DISC)**: a hint to a neighbouring AS about which entry point to use; optional and non-transitive.
- **Best path**: the single route a BGP speaker installs and advertises, chosen by comparing attributes in order.
- **AS_PATH prepending**: adding your own AS number repeatedly to make a path look longer and less preferred.

## Why it hurts

With two paths to the same prefix, sending traffic the "wrong" way costs money
and delay, and the choice looks arbitrary until you know the comparison order.

## Why the naive fix fails

Tuning a downstream metric without understanding precedence can do nothing:
LOCAL_PREF is compared before AS_PATH and MED, so a lower MED never wins if
LOCAL_PREF already decided the path.

## The mechanism

BGP compares, in order: Weight, LOCAL_PREF, locally originated, AS_PATH length,
ORIGIN, MED, eBGP over iBGP, IGP metric, then tie-breakers. Two knobs matter
here: `local-preference` (per-neighbour, inbound) and `as-path prepend`
(outbound). MED is only compared between paths from the same neighbour AS.

## Configure and inspect

On r1:
```
ip route get 10.2.2.100
vtysh -c 'show bgp ipv4 unicast'
```

## Common questions

- Why did my lower MED not change the path? MED is compared only within the same neighbour AS; across ASes it is ignored by default.
- Why is LOCAL_PREF not seen by the peer? LOCAL_PREF is local to the AS and is not sent over eBGP.
- How do I make one path less preferred? Prepend your AS on the outbound UPDATE so the AS_PATH is longer.
