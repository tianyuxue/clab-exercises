#!/bin/sh
# Fault: r1 uses the default timers (no explicit `neighbor ... timers`), so its
# OPEN proposes hold time 180. Set 3 9 (keepalive then hold) to make it propose 9.
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
 no neighbor 10.1.12.2 timers
exit
EOF
vtysh -c 'clear bgp *'
