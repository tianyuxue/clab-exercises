#!/bin/sh
# I AM NOT DONE
# Goal: sw1 is the core switch and must become the STP root bridge.
ip link set dev br0 type bridge priority 32768
