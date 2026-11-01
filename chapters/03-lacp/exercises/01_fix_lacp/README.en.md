# 01_fix_lacp

`srl1` and `srl2` are joined by two links bundled as `lag1` with LACP, but `lag1`
is down: neither member joins the forwarding set and `10.0.0.1/30` cannot reach
`10.0.0.2`.

## Cause

`oper-down-reason` says `no-active-links`. Both switches run `lacp-mode` PASSIVE,
so neither sends LACPDUs and both wait for the other to speak first. The links
are physically up, but negotiation never completes.

## Observe

Confirm the cause before changing anything:

```sh
docker exec <srl1> sr_cli -d "show lag"
```

Check the `lag1` state, each member's `oper-state`, and `oper-down-reason`.
`no-active-links` means one side must become active.

## Fix

Set `srl1` to ACTIVE so it starts sending LACPDUs:

```sh
docker exec <srl1> sr_cli -d "enter candidate; set / interface lag1 lag lacp lacp-mode ACTIVE; commit now"
```

`commit now` takes effect immediately; no restart needed. Run `show lag` again:
`lag1` should be up with both members in the bundle. `srl2` can stay PASSIVE,
since LACP needs only one active side.

Press Enter to verify; `f` re-injects the fault.
