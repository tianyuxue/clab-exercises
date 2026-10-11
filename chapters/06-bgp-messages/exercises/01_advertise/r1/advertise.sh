#!/bin/sh
# FAULT: r1 has no `no bgp ebgp-requires-policy`, so eBGP sends no UPDATEs
# (show bgp summary -> peerState "Policy", pfxSnt 0). Fix the running router.
ip link set eth1 up
ip addr replace 192.0.2.1/24 dev lo
vtysh <<'EOF'
configure terminal
interface eth1
 ip address 10.1.12.1/30
exit
router bgp 65001
 bgp router-id 10.1.12.1
 bgp ebgp-requires-policy
 neighbor 10.1.12.2 remote-as 65002
 network 192.0.2.0/24
exit
EOF
vtysh -c 'clear bgp *'
