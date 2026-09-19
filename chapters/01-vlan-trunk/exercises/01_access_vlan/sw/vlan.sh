#!/bin/sh
# I AM NOT DONE
# Goal: both access ports on sw must be in the same VLAN.
for v in 1 10 20; do
  bridge vlan del dev eth1 vid $v 2>/dev/null || true
  bridge vlan del dev eth2 vid $v 2>/dev/null || true
done
bridge vlan add dev eth1 vid 10 pvid untagged
bridge vlan add dev eth2 vid 20 pvid untagged
