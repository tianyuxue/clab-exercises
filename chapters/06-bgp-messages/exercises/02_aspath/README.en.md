# 02_aspath

`r1` advertises `192.0.2.0/24` with AS_PATH `65001`. Prepend `65001` twice on
the **outbound** UPDATE so the AS_PATH on the wire becomes `65001 65001 65001`.

## How to fix

Open a second terminal and log into the running routers (`make debug`, or `docker exec`):

- On `r1` add a route-map and apply it to the neighbor:
  `docker exec <r1> vtysh -c 'conf t' -c 'route-map PREPEND permit 10' -c 'set as-path prepend 65001 65001' -c 'router bgp 65001' -c 'neighbor 10.1.12.2 route-map PREPEND out'`
- The new attributes are sent on the next UPDATE, so reset the session:
  `docker exec <r1> vtysh -c 'clear bgp *'`

Inspect the wire yourself:
`docker exec <sniff> tshark -r /tmp/bgp.pcap -Y 'bgp.type==2 && ip.src==10.1.12.1' -T fields -e bgp.update.path_attribute.as_path_segment.as4`

Press Enter to verify; `f` re-injects the fault.
