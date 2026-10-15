#!/bin/sh
# FAULT: h4 tags its frames with VLAN 30, which no trunk carries, so nothing
# reaches h1. Fix the tag to 10. Fix the running host, not this file.
ip link del eth1.30 2>/dev/null || true
ip link del eth1.10 2>/dev/null || true
ip addr flush dev eth1 2>/dev/null || true
ip link add link eth1 name eth1.30 type vlan id 30
ip addr add 10.0.10.4/24 dev eth1.30
ip link set eth1 up
ip link set eth1.30 up
