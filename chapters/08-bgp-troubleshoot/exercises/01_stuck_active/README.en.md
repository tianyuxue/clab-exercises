# 01_stuck_active

## Task

Bring `edge`'s eBGP neighbor to Established.

## Cause

`edge` is `10.1.12.1/30`, `ext` is `10.1.12.2/30`, but `edge` configures neighbor
`10.1.12.9`. That address is off-link and unreachable, so TCP 179 never opens and
the FSM stays in Active.

## Observe

```sh
docker exec <edge> vtysh -c 'show bgp summary'
```

The neighbor sits in the Active/Connect column.

## Fix

Remove the wrong neighbor, add `10.1.12.2`, and clear the session:

```sh
docker exec <edge> vtysh -c 'conf t' -c 'router bgp 65001' -c 'no neighbor 10.1.12.9 remote-as 65002' -c 'neighbor 10.1.12.2 remote-as 65002' -c 'end' -c 'clear bgp *'
```

Press Enter to verify; `f` re-injects the fault.
