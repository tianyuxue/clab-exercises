#!/bin/sh
# FAULT: r1 advertises 192.0.2.0/24 with AS_PATH "65001" (no prepend).
# Add an outbound route-map prepending 65001 twice so the AS_PATH becomes
# "65001 65001 65001". Fix the running router, not this file.
ip link set eth1 up
ip addr replace 192.0.2.1/24 dev lo
vtysh <<'EOF'
configure terminal
no route-map PREPEND
interface eth1
 ip address 10.1.12.1/30
exit
router bgp 65001
 bgp router-id 10.1.12.1
 no bgp ebgp-requires-policy
 neighbor 10.1.12.2 remote-as 65002
 no neighbor 10.1.12.2 route-map PREPEND out
 network 192.0.2.0/24
exit
EOF
vtysh -c 'clear bgp *'
