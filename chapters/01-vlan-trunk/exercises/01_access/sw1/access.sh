#!/bin/sh
# FAULT: h2's access port (eth2) is in VLAN 20, so its untagged frames land in
# the wrong broadcast domain and h1 (VLAN 10) cannot reach it.
# Fix the running switch, not this file.
for p in eth1 eth2 eth3; do
  for v in 1 10 20 30; do bridge vlan del dev $p vid $v 2>/dev/null || true; done
done
bridge vlan add dev eth1 vid 10 pvid untagged
bridge vlan add dev eth2 vid 20 pvid untagged
