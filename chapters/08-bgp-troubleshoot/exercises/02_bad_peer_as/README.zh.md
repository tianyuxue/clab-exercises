# 02_bad_peer_as

`edge` 的 eBGP 会话始终建立不起来：对端拒绝了它的 OPEN。

## 修复步骤

在本章目录另开一个终端，登录 `ext`（`make debug` 或 `docker exec`）：

- 抓包确证错误：
  `docker exec <sniff> tshark -r /tmp/bgp.pcap -Y 'bgp.type==3' -T fields -e bgp.notify.major_error -e bgp.notify.minor_error_open`
  应看到 OPEN Message Error（major 2）与 Bad Peer AS（minor 2）。
- 在 `ext` 上把该邻居的 remote-as 改成与 `edge` 的 AS 一致：
  `docker exec <ext> vtysh -c 'conf t' -c 'router bgp 65002' -c 'neighbor 10.1.12.1 remote-as 65001' -c 'clear bgp *'`

按 Enter 验证；按 `f` 重新注入故障。
