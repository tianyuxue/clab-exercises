# 01_fix_root

`sw1-sw2-sw3` 三角环存在二层环路，STP 会通过阻塞一个端口来消除环路。当前 `sw2`
的桥优先级是 4096，抢占了根桥；核心交换机 `sw1` 才应该是根。

## 修复步骤

先查看 STP 状态，然后直接调整正在运行的 `sw1`：

- `docker exec <sw1> cat /sys/class/net/br0/bridge/{bridge_id,root_id,priority}`
- `docker exec <sw1> bridge -j link show`
- 把 `sw1` 的优先级调到低于 sw2 的 4096（0 合法），例如
  `docker exec <sw1> ip link set dev br0 type bridge priority 0`

改动立即生效；按 Enter 验证。务必保持 STP 启用——环路应通过阻塞端口消除，而不是
删除链路。按 `f`（fast reset）会重新注入故障，方便从头再来。
