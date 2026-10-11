#!/bin/sh
# FAULT: ext expects the neighbor in AS 65099, so it rejects edge's OPEN with
# NOTIFICATION "Bad Peer AS". Fix the running router, not this file.
ip link set eth1 up
ip addr replace 192.0.2.1/24 dev lo
vtysh <<'EOF'
configure terminal
interface eth1
 ip address 10.1.12.2/30
exit
router bgp 65002
 bgp router-id 10.0.0.3
 no bgp ebgp-requires-policy
 neighbor 10.1.12.1 remote-as 65099
 network 192.0.2.0/24
exit
EOF
