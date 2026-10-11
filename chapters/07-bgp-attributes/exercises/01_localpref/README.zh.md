# 01_localpref

`r1` 从 `r2` 与 `r3` 都学到 `10.2.2.0/24`，当前偏好经 `r3` 的路径。用 LOCAL_PREF
让它改走 `r2`。

## 修复步骤

在本章目录另开一个终端，登录 `r1`（`make debug` 或 `docker exec`）：

- 查看当前选择：`docker exec <r1> ip route get 10.2.2.100`
- 对从 `r2` 学到的路由设置 LOCAL_PREF：
  `docker exec <r1> vtysh -c 'conf t' -c 'route-map FROM_R2 permit 10' -c 'set local-preference 200' -c 'router bgp 65001' -c 'neighbor 10.1.12.2 route-map FROM_R2 in'`

LOCAL_PREF 对 RIB 立即生效。按 Enter 验证；按 `f` 重新注入故障。
