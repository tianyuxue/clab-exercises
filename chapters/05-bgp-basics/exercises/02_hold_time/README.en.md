# 02_hold_time

The session between `r1` and `r2` is established with the default timers. Make
`r1` propose a **9-second hold time** (keepalive 3s) so its next OPEN carries
`hold_time = 9`.

## How to fix

- Set the neighbor timers on `r1`:
  `docker exec <r1> vtysh -c 'conf t' -c 'router bgp 65001' -c 'neighbor 10.1.12.2 timers 9 3'`
- Timers only take effect on a new session, so reset it:
  `docker exec <r1> vtysh -c 'clear bgp *'`

The sniffer node captures BGP on the wire. Inspect it yourself with:
`docker exec <sniff> tshark -r /tmp/bgp.pcap -Y 'bgp.type==1 && ip.src==10.1.12.1' -T fields -e bgp.open.holdtime`

Press Enter to verify; `f` re-injects the fault.
