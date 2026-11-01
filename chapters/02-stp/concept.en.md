# STP/RSTP: Why a Second Cable Can Take Down the Network

## The failure

Two switches, one link, plus a second cable for redundancy. Plug it in and the
network collapses in seconds: latency spikes, pings stop, CPUs peg. Unplug the new
cable and everything recovers.

Ethernet frames have no TTL. With two paths, a broadcast circles forever, is
re-flooded on every lap, and saturates the links. MAC tables flap too, as one MAC
arrives on two ports.

## Why unplugging is not the answer

Pulling a cable removes the loop but also the redundancy you just paid for. Letting
both links forward is worse, because a flat Layer-2 network cannot have two active
paths. The fix is a protocol that keeps every cable physically up while forwarding
on a logical loop-free tree: STP.

## Key terms

- **Loop**: a path that returns a frame to a switch it already passed.
- **Broadcast storm**: a broadcast trapped in a loop, re-flooded and duplicated
  until links and CPUs saturate.
- **STP** (802.1D): keeps redundant links connected and builds a loop-free tree.
- **Root bridge**: the reference switch every other switch computes paths towards.
- **Bridge ID**: 16-bit priority plus 6-byte MAC; the lowest wins.
- **Path cost**: the metric for distance to the root; lower is better.
- **Port roles**: the **root port** is a bridge's best way to the root; one
  **designated port** per segment forwards; the rest are **blocked** (RSTP:
  alternate/backup).
- **RSTP** (802.1w): the modern version, converging in sub-seconds.

## How the tree is built

1. Every switch compares bridge IDs; the lowest becomes root (priority first, then
   MAC). The default priority 32768 means an unconfigured network picks the root by
   MAC. In the lab `sw2` uses 4096 and beats the default 32768 on `sw1` and `sw3`.
2. Each non-root switch picks one root port: the lowest-cost path to the root, with
   ties broken by neighbour bridge ID and port ID.
3. Each segment keeps one designated port forwarding; every other port is blocked.

A blocked port keeps its link up and still receives BPDUs, so it tracks the tree. If
the active path fails, the tree reconverges and it takes over. That is how STP
combines redundancy with a loop-free topology.

## Configure and inspect

STP is off by default on a Linux bridge; enable it when the bridge is created:

```sh
ip link add br0 type bridge stp_state 1 && ip link set br0 up
ip link set eth1 master br0 && ip link set eth2 master br0

# priority steps by 4096; lower values win the root election
ip link set dev br0 type bridge priority 4096
```

```sh
# this bridge's own ID
cat /sys/class/net/br0/bridge/bridge_id
# equal to bridge_id means this bridge is the root
cat /sys/class/net/br0/bridge/root_id
# per-port state: forwarding / blocking
bridge -j link show
```

Three timers drive convergence: `hello_time` is the BPDU interval, `max_age` is how
long without a neighbour message before a path is declared dead, and `forward_delay`
is the wait before a port forwards. Defaults take tens of seconds; the lab uses
`forward_delay 2`, `hello_time 1` and `max_age 4`.

## Common pitfalls

- **Root on an edge switch**: with no priority configured, MAC decides the root.
  Set a lower priority explicitly on the intended core switch.
- **Blocking is not down**: the link is up and standing by. Do not unplug cables or
  disable STP to force it to forward.
- **Re-election takes time**: changing the priority re-runs the election and briefly
  interrupts forwarding.
- **No load sharing**: STP removes loops but leaves one link idle. Using both links
  requires link aggregation (LACP).
