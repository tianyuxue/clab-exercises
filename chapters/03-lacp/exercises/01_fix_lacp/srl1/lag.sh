#!/bin/sh
# I AM NOT DONE
# Goal: bring lag1 up by fixing LACP negotiation.
sr_cli -d <<'SRLEOF'
enter candidate
set / interface ethernet-1/1 admin-state enable
set / interface ethernet-1/2 admin-state enable
set / interface ethernet-1/1 ethernet aggregate-id lag1
set / interface ethernet-1/2 ethernet aggregate-id lag1
set / interface lag1 admin-state enable
set / interface lag1 lag lag-type lacp
set / interface lag1 lag lacp lacp-mode PASSIVE
set / interface lag1 subinterface 0 admin-state enable
set / interface lag1 subinterface 0 ipv4 admin-state enable
set / interface lag1 subinterface 0 ipv4 address 10.0.0.1/30
set / network-instance default interface lag1.0
commit now
SRLEOF
