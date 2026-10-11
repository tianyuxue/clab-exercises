# 01_advertise

`r1`（AS 65001）与 `r2`（AS 65002）已建立会话，`r1` 也配了
`network 192.0.2.0/24`，但 `r2` 始终收不到该前缀。

## 修复步骤

- 在 `r1` 上运行 `docker exec <r1> vtysh -c 'show bgp summary'`；对端的
  `State/PfxRcd` 显示在 `Policy` 列，且 `pfxSnt 0`。
- FRR 的 eBGP 默认要求策略。放开它：
  `docker exec <r1> vtysh -c 'conf t' -c 'router bgp 65001' -c 'no bgp ebgp-requires-policy'`

改动立即生效。按 Enter 验证；按 `f` 重新注入故障。
