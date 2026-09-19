# 01_fix_root

`sw1-sw2-sw3` 三角环存在二层环路，STP 会通过阻塞一个端口来消除环路。当前 `sw2`
的桥优先级是 4096，抢占了根桥；核心交换机 `sw1` 才应该是根。

## 修复步骤

先查看 STP 状态，然后在宿主机上编辑 `sw1/stp.sh`，由 watch 自动 reload 进 `sw1`：

- `docker exec <sw1> cat /sys/class/net/br0/bridge/{bridge_id,root_id,priority}`
- `docker exec <sw1> bridge -j link show`
- 把 `sw1` 的优先级调到低于 sw2 的 4096（0 合法），并删除 `I AM NOT DONE`

保存后自动 reload；也可按 Enter 强制验证。务必保持 STP 启用——环路应通过阻塞端口
消除，而不是删除链路。
