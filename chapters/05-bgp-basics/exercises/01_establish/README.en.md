# 01_establish

`r1` (AS 65001, 10.1.12.1/30) and `r2` (AS 65002, 10.1.12.2/30) are directly connected, but the neighbor never reaches Established.

## Cause

`r2` expects `10.1.12.1` in AS 65099. r1's OPEN says My AS 65001, so r2 returns NOTIFICATION "Bad Peer AS" and closes TCP; r1 retries and is rejected again.

## Observe

Capture port 179 on `sniff` and look for the NOTIFICATION:

```sh
docker exec <sniff> tshark -i any -f 'tcp port 179' -Y 'bgp.type==3' -T fields -e bgp.notification.error_code -e bgp.notification.error_subcode
```

Before the fix this shows error code 2, subcode 2. Check both neighbor tables with:

```sh
docker exec -it <r1> vtysh -c 'show bgp summary'
docker exec -it <r2> vtysh -c 'show bgp summary'
```

## Fix

Set r2's expected AS to 65001:

```sh
docker exec <r2> vtysh -c 'conf t' -c 'router bgp 65002' -c 'neighbor 10.1.12.1 remote-as 65001'
```

The change applies immediately. Press Enter to verify; `f` re-injects the fault.
