#!/bin/sh
# r1 is correctly configured. The fault is on r2.
# Fix the running router, not this file.
ip link set eth1 up
vtysh <<'EOF'
configure terminal
interface eth1
 ip address 10.1.12.1/30
exit
router bgp 65001
 bgp router-id 10.1.12.1
 no bgp ebgp-requires-policy
 neighbor 10.1.12.2 remote-as 65002
exit
EOF
