# 02_aspath

`r1` advertises `192.0.2.0/24` with AS_PATH `65001`. Prepend `65001` twice on
the outbound UPDATE so the peer sees `65001,65001,65001`.

## Cause

AS_PATH is a path attribute; each AS appends its own number. r1 already writes
`65001` once, so an outbound policy must add two more copies. Only the sent copy
changes; the local BGP table keeps its own AS_PATH.

## Observe

The sniffer bridges r1 and r2 and sees all port 179 traffic. Read the current
AS_PATH:

```sh
docker exec <sniff> tshark -r /tmp/bgp.pcap -Y 'bgp.type==2 && ip.src==10.1.12.1' -T fields -e bgp.update.path_attribute.as_path_segment.as4 | tail -1
```

Before the fix, the last line holds only `65001`.

## Fix

```sh
docker exec <r1> vtysh -c 'conf t' -c 'route-map PREPEND permit 10' -c 'set as-path prepend 65001 65001' -c 'router bgp 65001' -c 'neighbor 10.1.12.2 route-map PREPEND out'
docker exec <r1> vtysh -c 'clear bgp *'
```

The new attributes go out in the next UPDATE, so the reset is required. Re-run the
tshark command; AS_PATH should read `65001,65001,65001`.

Press Enter to verify; `f` re-injects the fault.
