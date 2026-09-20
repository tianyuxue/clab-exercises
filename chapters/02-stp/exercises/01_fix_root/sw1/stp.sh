#!/bin/sh
# Fault injection: sw1 keeps the default priority 32768, so sw2 (4096) wins the
# root election. Fix the running switch, not this file.
ip link set dev br0 type bridge priority 32768
