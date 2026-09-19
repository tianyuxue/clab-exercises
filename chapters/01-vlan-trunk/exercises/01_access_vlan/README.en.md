# 01_access_vlan

`sw` runs a Linux bridge with VLAN filtering. `h1` (10.0.1.1/24) and
`h2` (10.0.1.2/24) are on the same subnet, yet they cannot reach each other
because the two access ports use different PVIDs.

## How to fix

Open another terminal in the chapter directory and run `make debug` (or use
`docker exec`), inspect the bridge, then edit `sw/vlan.sh` on the host:

- `docker exec <sw> bridge vlan show`
- put both `eth1` and `eth2` in VLAN 10 with `pvid untagged`
- remove the `I AM NOT DONE` line

Saving the file makes `clablings watch` re-copy it into `sw` and run the reload
script automatically. You can also press Enter to force verification.
