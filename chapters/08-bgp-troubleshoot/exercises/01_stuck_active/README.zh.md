# 01_stuck_active

`edge` 的一个 eBGP 邻居一直停在 Active，会话建立不起来。

## 修复步骤

在本章目录另开一个终端，登录 `edge`（`make debug` 或 `docker exec`）：

- `docker exec <edge> vtysh -c 'show bgp summary'` —— 邻居处于 Active/Connect 列。
- 对照链路网段（`10.1.12.0/30`）检查配置的邻居地址。删掉错误的、加上 `10.1.12.2`：
  `docker exec <edge> vtysh -c 'conf t' -c 'router bgp 65001' -c 'no neighbor 10.1.12.9 remote-as 65002' -c 'neighbor 10.1.12.2 remote-as 65002' -c 'clear bgp *'`

按 Enter 验证；按 `f` 重新注入故障。
