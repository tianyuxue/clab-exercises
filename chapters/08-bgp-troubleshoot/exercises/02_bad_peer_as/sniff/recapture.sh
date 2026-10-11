#!/bin/sh
pkill -x tcpdump 2>/dev/null || true
rm -f /tmp/bgp.pcap
setsid tcpdump -U -i any -w /tmp/bgp.pcap tcp port 179 >/dev/null 2>&1 </dev/null &
