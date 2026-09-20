# 01_access_vlan

`sw` runs a Linux bridge with VLAN filtering. `h1` (10.0.1.1/24) and
`h2` (10.0.1.2/24) are on the same subnet, yet they cannot reach each other
because the two access ports use different PVIDs.

## How to fix

Open another terminal in the chapter directory and configure the running switch
directly (`make debug`, or `docker exec`):

- `docker exec <sw> bridge vlan show` — see the PVID of each port
- put both `eth1` and `eth2` in VLAN 10 with `pvid untagged`, e.g.
  `docker exec <sw> bridge vlan del dev eth2 vid 20 && docker exec <sw> bridge vlan add dev eth2 vid 10 pvid untagged`

The change takes effect immediately. Press Enter to verify; `f` (fast reset)
re-injects the fault if you want to start over.
