# 02_hold_time

The session is up with default timers. r1's OPEN currently proposes a 180-second Hold Time; make it propose 9 seconds with a 3-second KEEPALIVE.

## Cause

Hold Time and the KEEPALIVE interval are negotiated in the OPEN; defaults are 180 and 60 seconds. To detect a dead r1 within 9 seconds, r1 must propose Hold Time 9 and KEEPALIVE 3. Timers apply only to a new session, so a config change needs a reset.

## Observe

`sniff` captures continuously to `/tmp/bgp.pcap`. Read r1's OPEN:

```sh
docker exec <sniff> tshark -r /tmp/bgp.pcap -Y 'bgp.type==1 && ip.src==10.1.12.1' -T fields -e bgp.open.holdtime
```

The last line is 180 before the fix and 9 after the session is reset.

## Fix

Set the neighbor timers on r1 (FRR order: KEEPALIVE then Hold Time):

```sh
docker exec <r1> vtysh -c 'conf t' -c 'router bgp 65001' -c 'neighbor 10.1.12.2 timers 3 9'
```

Reset the session so the new timers are negotiated:

```sh
docker exec <r1> vtysh -c 'clear bgp *'
```

Press Enter to verify; `f` re-injects the fault.
