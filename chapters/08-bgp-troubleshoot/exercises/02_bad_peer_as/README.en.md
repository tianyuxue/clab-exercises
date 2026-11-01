# 02_bad_peer_as

## Task

Get `edge`'s eBGP session past the OPEN exchange.

## Cause

`edge` sends AS 65001, but `ext` expects `remote-as 65099`. `ext` rejects the OPEN
with NOTIFICATION OPEN Message Error (2/2), Bad Peer AS, then closes the session.

## Observe

```sh
docker exec <sniff> tshark -r /tmp/bgp.pcap -Y 'bgp.type==3' -T fields -e bgp.notify.major_error -e bgp.notify.minor_error_open
```

Look for major 2, minor 2.

## Fix

On `ext`, set the neighbor's remote-as to `edge`'s real AS, then clear the session:

```sh
docker exec <ext> vtysh -c 'conf t' -c 'router bgp 65002' -c 'neighbor 10.1.12.1 remote-as 65001' -c 'end' -c 'clear bgp *'
```

Press Enter to verify; `f` re-injects the fault.
