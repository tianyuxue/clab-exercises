# 01_establish

`r1`（AS 65001，10.1.12.1/30）与 `r2`（AS 65002，10.1.12.2/30）本应建立 eBGP 会话，
但 `r2` 拒绝了 `r1` 的 OPEN：该邻居的 `remote-as` 配错了。

## 修复步骤

在本章目录另开一个终端，直接登录正在运行的路由器（`make debug` 或 `docker exec`）：

- `docker exec -it <r1> vtysh -c 'show bgp summary'`（`<r2>` 同理）
- 在 `r2` 上把该邻居的 remote-as 改成 `r1` 的 AS：
  `docker exec <r2> vtysh -c 'conf t' -c 'router bgp 65002' -c 'neighbor 10.1.12.1 remote-as 65001'`

改动立即生效。按 Enter 验证；按 `f`（fast reset）会重新注入故障。
