# 01_fix_lacp

`srl1` and `srl2` are joined by two links, bundled as `lag1` with LACP. The bundle
does not come up: both switches run LACP in **PASSIVE** mode, so neither side ever
sends LACPDUs.

## How to fix

Inspect the LAG and fix the running `srl1` directly:

- `docker exec <srl1> sr_cli -d "show lag"` (look at `oper-down-reason`)
- set `lacp-mode` to `ACTIVE` on srl1, e.g.
  `docker exec <srl1> sr_cli -d "enter candidate; set / interface lag1 lag lacp lacp-mode ACTIVE; commit now"`

The change takes effect immediately; press Enter to verify. Only one side needs to
be ACTIVE; srl2 can stay PASSIVE. `f` (fast reset) re-injects the fault if you want
to start over.
