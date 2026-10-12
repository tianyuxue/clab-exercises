# 01_speaker

Write a minimal BGP speaker in C that peers with `r1` (AS 65002) and advertises
`192.0.2.0/24`. Your program takes the peer address as `argv[1]`.

## Milestones

1. **Connect and OPEN** — TCP-connect to the peer on port 179 and send a valid
   OPEN (`version=4`, `my AS=65001`, `hold time=90`, `BGP identifier=10.1.12.1`,
   no optional parameters). `r1`'s log/`show bgp summary` should show the peer.
2. **Established** — read the peer OPEN, send a KEEPALIVE, read the peer
   KEEPALIVE; the session becomes Established. Send a KEEPALIVE every 30s
   (hold/3) so it stays up.
3. **UPDATE** — send an UPDATE with ORIGIN, AS_PATH (65001), NEXT_HOP
   `10.1.12.1`, and NLRI `192.0.2.0/24`. `r1` then learns the prefix.

## Build and run

`clablings` builds `bgp-speaker` (see `Makefile`) and runs it on the `speaker`
node. Logs go to `/tmp/bgp.log` on that node:
`docker exec <speaker> cat /tmp/bgp.log`

Remember to delete the `// I AM NOT DONE` line from `src/main.c` when done, then
press Enter to verify.
