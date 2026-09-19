# 01_fix_lacp

`srl1` and `srl2` are joined by two links, bundled as `lag1` with LACP. The bundle
does not come up: both switches run LACP in **PASSIVE** mode, so neither side ever
sends LACPDUs.

## How to fix

Inspect the LAG, then edit `srl1/lag.sh` on the host and let watch reload it:

- `docker exec <srl1> sr_cli -d "show lag"` (look at `oper-down-reason`)
- change `lacp-mode PASSIVE` to `ACTIVE` on srl1, remove `I AM NOT DONE`

Saving triggers reload; Enter forces verification. Only one side needs to be
ACTIVE; srl2 can stay PASSIVE.
