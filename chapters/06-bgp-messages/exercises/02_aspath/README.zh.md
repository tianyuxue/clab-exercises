# 02_aspath

`r1` 通告 `192.0.2.0/24` 时 AS_PATH 为 `65001`。在**出向** UPDATE 上把 `65001`
prepend 两次，使线上的 AS_PATH 变为 `65001 65001 65001`。

## 修复步骤

在本章目录另开一个终端，登录正在运行的路由器（`make debug` 或 `docker exec`）：

- 在 `r1` 上建一条 route-map 并应用到邻居：
  `docker exec <r1> vtysh -c 'conf t' -c 'route-map PREPEND permit 10' -c 'set as-path prepend 65001 65001' -c 'router bgp 65001' -c 'neighbor 10.1.12.2 route-map PREPEND out'`
- 新属性在下一次 UPDATE 时发送，因此重置会话：
  `docker exec <r1> vtysh -c 'clear bgp *'`

可自行查看线上报文：
`docker exec <sniff> tshark -r /tmp/bgp.pcap -Y 'bgp.type==2 && ip.src==10.1.12.1' -T fields -e bgp.update.path_attribute.as_path_segment.as4`

按 Enter 验证；按 `f` 重新注入故障。
