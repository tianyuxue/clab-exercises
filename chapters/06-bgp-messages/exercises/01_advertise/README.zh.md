# 01_advertise

`r1`（AS 65001，10.1.12.1/30）与 `r2`（AS 65002，10.1.12.2/30）已建立会话，
`r1` 也配了 `network 192.0.2.0/24`，但 `r2` 始终收不到该前缀。

## 修复步骤

在本章目录另开一个终端，登录正在运行的路由器（`make debug` 或 `docker exec`）：

- `docker exec -it <r1> vtysh -c 'show bgp summary'` —— 邻居显示 `peerState "Policy"`、`pfxSnt 0`。
- FRR 的 eBGP 默认要求策略。在 `r1` 上放开它：
  `docker exec <r1> vtysh -c 'conf t' -c 'router bgp 65001' -c 'no bgp ebgp-requires-policy'`
- UPDATE 只在新会话上发送，因此重置会话：
  `docker exec <r1> vtysh -c 'clear bgp *'`

按 Enter 验证；按 `f` 重新注入故障。
