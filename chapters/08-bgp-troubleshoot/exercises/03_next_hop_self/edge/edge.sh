#!/bin/sh
# FAULT: no next-hop-self on the iBGP session, so core receives 192.0.2.0/24
# with next-hop 10.1.12.2 (unreachable) -> learned but not installed.
# Add `neighbor 10.1.1.2 next-hop-self`. Fix the running router, not this file.
ip link set eth1 up; ip link set eth2 up
vtysh <<'EOF'
configure terminal
interface eth1
 ip address 10.1.1.1/30
exit
interface eth2
 ip address 10.1.12.1/30
exit
no router bgp 65001
router bgp 65001
 bgp router-id 10.0.0.1
 no bgp ebgp-requires-policy
 neighbor 10.1.12.2 remote-as 65002
 neighbor 10.1.1.2 remote-as 65001
 no neighbor 10.1.1.2 next-hop-self
exit
EOF
vtysh -c 'clear bgp *'
