#!/bin/sh
# FAULT: r2 expects the neighbor in AS 65099, so the OPEN is rejected
# (NOTIFICATION "Bad Peer AS") and the session never establishes.
# Fix the running router, not this file.
ip link set eth1 up
vtysh <<'EOF'
configure terminal
interface eth1
 ip address 10.1.12.2/30
exit
router bgp 65002
 bgp router-id 10.1.12.2
 no bgp ebgp-requires-policy
 neighbor 10.1.12.1 remote-as 65099
exit
EOF
