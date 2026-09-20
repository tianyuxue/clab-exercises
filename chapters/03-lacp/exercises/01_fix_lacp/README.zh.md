# 01_fix_lacp

`srl1` 与 `srl2` 之间用两条链路捆绑为 `lag1`，使用 LACP。但聚合起不来：两台交换机的
LACP 都是 **PASSIVE**，没有任何一侧主动发送 LACPDU。

## 修复步骤

先查看聚合，然后直接修复正在运行的 `srl1`：

- `docker exec <srl1> sr_cli -d "show lag"`（看 `oper-down-reason`）
- 把 srl1 的 `lacp-mode` 改为 `ACTIVE`，例如
  `docker exec <srl1> sr_cli -d "enter candidate; set / interface lag1 lag lacp lacp-mode ACTIVE; commit now"`

改动立即生效；按 Enter 验证。只要一侧是 ACTIVE 即可，srl2 保持 PASSIVE 没问题。
按 `f`（fast reset）会重新注入故障，方便从头再来。
