# 02_aspath

`r1` 当前偏好经 `r2` 的路径。在 `r2` 的**出向** UPDATE 上 prepend 本 AS 号，使
`r1` 切换到 `r3`（其 AS_PATH 更短）。

## 修复步骤

在本章目录另开一个终端，登录 `r2`（`make debug` 或 `docker exec`）：

- 在 `r2` 上建一条 route-map 并对 `r1` 应用为出向：
  `docker exec <r2> vtysh -c 'conf t' -c 'route-map PAD_65002 permit 10' -c 'set as-path prepend 65002 65002' -c 'router bgp 65002' -c 'neighbor 10.1.12.1 route-map PAD_65002 out'`
- 新属性在下一次 UPDATE 时发送，因此重置会话：
  `docker exec <r2> vtysh -c 'clear bgp *'`

按 Enter 验证；按 `f` 重新注入故障。
