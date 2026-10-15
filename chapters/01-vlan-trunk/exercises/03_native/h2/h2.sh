#!/bin/sh
ip addr flush dev eth1 2>/dev/null || true
ip addr add 10.0.20.2/24 dev eth1
ip link set eth1 up
