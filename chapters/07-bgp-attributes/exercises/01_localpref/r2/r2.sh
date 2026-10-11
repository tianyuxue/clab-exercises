#!/bin/sh
ip link set eth1 up; ip link set eth2 up
vtysh <<'EOF'
configure terminal
interface eth1
 ip address 10.1.12.2/30
exit
interface eth2
 ip address 10.2.2.2/24
exit
router bgp 65002
 bgp router-id 10.0.0.3
 no bgp ebgp-requires-policy
 neighbor 10.1.12.1 remote-as 65001
 network 10.2.2.0/24
exit
EOF
