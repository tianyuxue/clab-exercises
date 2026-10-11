# 02_bad_peer_as

`edge`'s eBGP session never establishes: the peer rejects its OPEN.

## How to fix

Open a second terminal and log into `ext` (`make debug`, or `docker exec`):

- Read the wire to confirm the error:
  `docker exec <sniff> tshark -r /tmp/bgp.pcap -Y 'bgp.type==3' -T fields -e bgp.notify.major_error -e bgp.notify.minor_error_open`
  You should see OPEN Message Error (major 2) with Bad Peer AS (minor 2).
- On `ext` set the neighbor's remote-as to match `edge`'s AS:
  `docker exec <ext> vtysh -c 'conf t' -c 'router bgp 65002' -c 'neighbor 10.1.12.1 remote-as 65001' -c 'clear bgp *'`

Press Enter to verify; `f` re-injects the fault.
