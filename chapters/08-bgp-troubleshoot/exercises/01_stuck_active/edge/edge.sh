#!/bin/sh
# FAULT: the eBGP neighbor address is wrong (10.1.12.9), so it is unreachable
# and the session stays in Active/Connect. Fix the running router, not this file.
ip link set eth1 up; ip link set eth2 up
vtysh <<'EOF'
configure terminal
interface eth1
 ip address 10.1.1.1/30
exit
interface eth2
 ip address 10.1.12.1/30
exit
router bgp 65001
 bgp router-id 10.0.0.1
 no bgp ebgp-requires-policy
 neighbor 10.1.12.9 remote-as 65002
 neighbor 10.1.1.2 remote-as 65001
exit
EOF
vtysh -c 'clear bgp *'
