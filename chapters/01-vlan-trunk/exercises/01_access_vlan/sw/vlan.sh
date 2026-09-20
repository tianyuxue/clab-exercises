#!/bin/sh
# Fault injection: eth1 is in VLAN 10, eth2 in VLAN 20 (different PVIDs).
# Fix the running switch, not this file.
for v in 1 10 20; do
  bridge vlan del dev eth1 vid $v 2>/dev/null || true
  bridge vlan del dev eth2 vid $v 2>/dev/null || true
done
bridge vlan add dev eth1 vid 10 pvid untagged
bridge vlan add dev eth2 vid 20 pvid untagged
