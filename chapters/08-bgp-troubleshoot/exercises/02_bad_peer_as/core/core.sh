#!/bin/sh
ip link set eth1 up
vtysh <<'EOF'
configure terminal
interface eth1
 ip address 10.1.1.2/30
exit
router bgp 65001
 bgp router-id 10.0.0.2
 neighbor 10.1.1.1 remote-as 65001
exit
EOF
