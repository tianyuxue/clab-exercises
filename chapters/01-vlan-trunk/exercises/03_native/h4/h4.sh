#!/bin/sh
ip link del eth1.10 2>/dev/null || true
ip link del eth1.30 2>/dev/null || true
ip addr flush dev eth1 2>/dev/null || true
ip addr add 10.0.20.1/24 dev eth1
ip link set eth1 up
