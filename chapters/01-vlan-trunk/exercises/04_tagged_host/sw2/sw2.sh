#!/bin/sh
for p in eth1 eth2 eth3; do
  for v in 1 10 20 30; do bridge vlan del dev $p vid $v 2>/dev/null || true; done
done
bridge vlan add dev eth1 vid 10
bridge vlan add dev eth2 vid 10 pvid untagged
bridge vlan add dev eth3 vid 10
