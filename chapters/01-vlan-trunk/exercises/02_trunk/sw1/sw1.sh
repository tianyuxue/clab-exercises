#!/bin/sh
# FAULT: the trunk port (eth3) does not carry VLAN 10, so frames from h1 are
# dropped instead of crossing to sw2. Fix the running switch, not this file.
for p in eth1 eth2 eth3; do
  for v in 1 10 20 30; do bridge vlan del dev $p vid $v 2>/dev/null || true; done
done
bridge vlan add dev eth1 vid 10 pvid untagged
bridge vlan add dev eth2 vid 10 pvid untagged
# eth3 trunk intentionally missing VLAN 10
