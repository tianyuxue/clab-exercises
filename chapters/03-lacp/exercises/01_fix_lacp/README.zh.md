# 01_fix_lacp

`srl1` 与 `srl2` 之间用两条链路捆绑为 `lag1`，使用 LACP。但聚合起不来：两台交换机的
LACP 都是 **PASSIVE**，没有任何一侧主动发送 LACPDU。

## 修复步骤

先查看聚合，然后在宿主机上编辑 `srl1/lag.sh`，由 watch 自动 reload：

- `docker exec <srl1> sr_cli -d "show lag"`（看 `oper-down-reason`）
- 把 srl1 的 `lacp-mode PASSIVE` 改为 `ACTIVE`，并删除 `I AM NOT DONE`

保存后自动 reload；按 Enter 强制验证。只要一侧是 ACTIVE 即可，srl2 保持 PASSIVE 没问题。
