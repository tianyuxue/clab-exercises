# 03_next_hop_self

`core` 从 `edge` 经 iBGP 学到了 `192.0.2.0/24`，却没有安装：其 NEXT_HOP 是外部对端
的地址，`core` 无法到达。

## 修复步骤

在本章目录另开一个终端，登录路由器（`make debug` 或 `docker exec`）：

- 在 `core`：`docker exec <core> vtysh -c 'show bgp ipv4 unicast 192.0.2.0/24'` ——
  该路径无效，因为 NEXT_HOP 不可达。
- 在 `edge`：让 iBGP 通告使用 `edge` 自己的地址：
  `docker exec <edge> vtysh -c 'conf t' -c 'router bgp 65001' -c 'neighbor 10.1.1.2 next-hop-self' -c 'end' -c 'clear bgp *'`

按 Enter 验证；按 `f` 重新注入故障。
