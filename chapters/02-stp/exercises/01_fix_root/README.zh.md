# 01_fix_root

先看现象：`sw1`、`sw2`、`sw3` 围成一个三角，STP 已经挡住其中一个口，`h1` 也能 ping 通 `h2`。表面看网络是好的。可一查根桥，发现是 `sw2`。

## 问题在哪

`sw2` 的优先级是 4096，`sw1` 和 `sw3` 还是默认的 32768。桥 ID 最小的当根，所以 `sw2` 赢下了选举。

可 `sw2` 位置偏，上行带宽也小。根桥一旦变化，整棵树的路径都要重算，最该当核心的 `sw1` 反而在后面跟着走。按规划，根桥应该是 `sw1`。

## 抓包或观察

先确认现在谁在当根：

```sh
docker exec <sw1> cat /sys/class/net/br0/bridge/{bridge_id,root_id,priority}
docker exec <sw1> bridge -j link show
```

`root_id` 和 `bridge_id` 不一样，说明 `sw1` 不是根。再去 `sw2` 上看一眼，两个值一致，根就在它身上。

`bridge -j link show` 里能看到三角中哪个口被阻塞。阻塞的口链路仍然是 up，只是不转发，这是 STP 消环的正常结果。

## 动手修

把 `sw1` 的优先级调到低于 4096。`0` 也合法：

```sh
docker exec <sw1> ip link set dev br0 type bridge priority 0
```

改完等树重新收敛，再按 Enter 验证。STP 要一直开着，消环靠阻塞端口，不是删链路。想从头再来，按 `f` 重新注入故障。
