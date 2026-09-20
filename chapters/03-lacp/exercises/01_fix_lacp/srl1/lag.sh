#!/bin/sh
# Fault injection: both sides run lacp-mode PASSIVE, so lag1 never comes up.
# Fix the running switch, not this file.
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
