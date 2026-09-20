# STP/RSTP

## Scenario

Two switches are connected by **two** cables, so that one can fail without
cutting the network in half. The moment the second cable is plugged in, the
network collapses: links saturate and switches pin their CPUs, within seconds.

## Terms

- **Loop**: a path along which a frame can return to a switch it has already
  passed. Ethernet frames have no TTL, so a looping frame never dies.
- **Broadcast storm**: a broadcast frame trapped in a loop. Every lap it is
  re-flooded and usually duplicated, so the traffic multiplies until the links
  and switch CPUs are saturated.
- **STP** (Spanning Tree Protocol, 802.1D): a protocol that keeps redundant links
  *physically* connected but builds a *logical* loop-free tree on top of them.
- **Root bridge**: the single reference switch all other switches compute their
  paths towards.
- **Bridge ID**: a switch's identity for the election — a 16-bit **priority**
  followed by its 6-byte MAC. The **lowest** bridge ID wins.
- **Path cost**: a metric for the distance to the root; the lower the cost, the
  better the path.
- **Port roles**: the **root port** is a bridge's best path to the root; a
  **designated port** is the best port on a segment; **blocked** (RSTP:
  alternate/backup) ports forward nothing but are kept as backups.
- **RSTP** (802.1w): the modern version; it converges in sub-seconds instead of
  tens of seconds.

## Why it hurts

A loop has no TTL to stop a frame, so one broadcast is enough: the frame circles
the loop, is duplicated every lap, and the network melts in seconds. The same
loop also makes the MAC tables unstable, because each switch keeps seeing the
same MAC arriving from two different ports.

## Why the naive fix fails

Removing one of the two cables stops the loop, but then you are back to a single
link with no redundancy — the thing you added the second cable for. Disabling STP
to "let both links forward" only brings the storm back, because a flat Layer-2
network cannot have two active paths between the same switches.

## The mechanism

STP keeps both cables physically up and builds a **loop-free tree** logically:

1. All switches elect one **root bridge**: the one with the **lowest bridge ID**
   (priority, then MAC).
2. Every other switch picks exactly one **root port** — the lowest-cost path
   towards the root.
3. On each segment, one **designated port** forwards; every other port is
   **blocked**.

The blocked port carries no traffic, so the loop is gone, but it keeps listening
for STP frames: if the active path fails, the tree reconverges and the blocked
port takes over. That is why STP gives you redundancy **and** a loop-free network.

## Configure and inspect

On a Linux bridge, STP is off by default; enable it on the bridge:

```sh
ip link add br0 type bridge stp_state 1 && ip link set br0 up
ip link set eth1 master br0 && ip link set eth2 master br0

# lower bridge ID wins the root election (priority is a multiple of 4096)
ip link set dev br0 type bridge priority 4096

# inspect: is this bridge the root, and which ports are forwarding?
cat /sys/class/net/br0/bridge/bridge_id     # this bridge's own ID
cat /sys/class/net/br0/bridge/root_id       # equal to bridge_id  => I am root
bridge -j link show                         # per-port state: forwarding/blocking
```

Default STP timers make the first convergence take tens of seconds; a lab can
speed it up with `forward_delay`, `hello_time` and `max_age`.

## Common questions

- **Default priority 32768**: with no priority configured, the **MAC address**
  decides the root — the result is arbitrary from an operations point of view.
  Always set the priority on the intended root.
- **Blocked is not down**: a blocked port still has link up and can take over;
  do not "fix" a blocking port by unplugging links.
- **Re-election**: changing the priority re-runs the election; expect a short
  reconvergence.
- **Timers**: with default timers, initial convergence is slow; the lab tunes
  them so you do not wait 30 seconds.
