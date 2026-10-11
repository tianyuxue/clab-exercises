#!/bin/sh
# FAULT/BASELINE: no AS_PATH manipulation, so r1 follows router-id and prefers
# r2 (10.0.0.2 < 10.0.0.3). Prepend on r2's outbound to make r1 prefer r3.
# Also clear any LOCAL_PREF left by 01_localpref. Fix the running router.
ip link set eth1 up; ip link set eth2 up; ip link set eth3 up
vtysh <<'EOF'
configure terminal
interface eth1
 ip address 10.0.1.1/24
exit
interface eth2
 ip address 10.1.12.1/30
exit
interface eth3
 ip address 10.1.13.1/30
exit
no route-map FROM_R2
no router bgp 65001
router bgp 65001
 bgp router-id 10.0.0.1
 bgp bestpath compare-routerid
 no bgp ebgp-requires-policy
 neighbor 10.1.12.2 remote-as 65002
 neighbor 10.1.13.2 remote-as 65003
 no neighbor 10.1.12.2 route-map FROM_R2 in
 network 10.0.1.0/24
exit
EOF
vtysh -c 'clear bgp *'
