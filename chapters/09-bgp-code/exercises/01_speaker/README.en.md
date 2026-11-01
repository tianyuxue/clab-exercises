# 01_speaker

`r1` already has an AS 65001 neighbor at `10.1.12.1`, but it never leaves
`Active`: nothing on the speaker side is listening.

## The task

Connect to `r1:179`, reach Established, and advertise `192.0.2.0/24`. Three
milestones:

1. **Connect and OPEN**: send a valid OPEN (`version=4`, `my AS=65001`,
   `hold time=90`, `BGP identifier=10.1.12.1`, zero optional parameters). The
   peer should appear in `show bgp summary`.
2. **Established**: read the peer OPEN, send KEEPALIVE, read the peer KEEPALIVE.
   Then send a KEEPALIVE every 30s (hold/3) so the 90s hold timer never expires.
3. **UPDATE**: advertise `192.0.2.0/24` with ORIGIN, AS_PATH (65001) and
   NEXT_HOP `10.1.12.1`.

`src/main.c` takes the peer address as `argv[1]` and already provides
`tcp_connect`, `send_all`, `recv_message`, `put16` and `put32`. The three
`build_*` functions and `main`'s sequence are empty.

## Observe

On `r1`:

```sh
docker exec <r1> vtysh -c 'show bgp summary'
docker exec <r1> vtysh -c 'show bgp ipv4 unicast'
```

Expect `Established` and one route for `192.0.2.0/24` (total 1).

The program logs on the speaker node:

```sh
docker exec <speaker> cat /tmp/bgp.log
```

To check bytes, capture port 179 on the speaker; `-X` prints hex. OPEN is 29
bytes starting with sixteen `ff`, KEEPALIVE is 19.

```sh
docker exec <speaker> tcpdump -i eth1 -nn -X port 179
```

## Fix

Fill in the three `build_*` functions, then wire up `main`: connect, send OPEN,
read OPEN, send KEEPALIVE, read KEEPALIVE, send UPDATE, keep sending KEEPALIVE
every 30s.

To catch compiler errors locally, run `make` in the exercise directory; clablings
rebuilds with the `gcc:13` image and runs the binary on the speaker node.

```sh
make
```

Delete the first-line `// I AM NOT DONE`, then press Enter in clablings. The
assertions check, in order: sentinel removed, peer Established, one route
learned, and `r1` can ping `192.0.2.1`.

This sequence is enough here: FRR sends its OPEN immediately after the TCP
connection, and nothing after Established needs a reply. A fuller speaker would
also validate message types, answer with NOTIFICATION on error, and use the
smaller hold time from both OPENs.
