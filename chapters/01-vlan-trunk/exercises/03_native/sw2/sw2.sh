#!/bin/sh
# FAULT: sw2's trunk port has the default PVID (1), so untagged VLAN-20 frames
# from sw1 land in VLAN 1 and never reach h4. Fix the running switch.
for p in eth1 eth2 eth3; do
  for v in 1 10 20 30; do bridge vlan del dev $p vid $v 2>/dev/null || true; done
done
bridge vlan add dev eth1 vid 10
# eth1 trunk intentionally missing `vid 20 pvid untagged`
bridge vlan add dev eth2 vid 10 pvid untagged
bridge vlan add dev eth3 vid 20 pvid untagged
