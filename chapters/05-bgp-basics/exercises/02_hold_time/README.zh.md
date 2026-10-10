# 02_hold_time

`r1` 与 `r2` 的会话当前以默认计时器建立。让 `r1` 提议 **9 秒 hold time**（keepalive 3 秒），
使其下一次 OPEN 携带 `hold_time = 9`。

## 修复步骤

- 在 `r1` 上设置邻居计时器（FRR 的顺序是先 keepalive 后 hold time）：
  `docker exec <r1> vtysh -c 'conf t' -c 'router bgp 65001' -c 'neighbor 10.1.12.2 timers 3 9'`
- 计时器只对新会话生效，因此重置它：
  `docker exec <r1> vtysh -c 'clear bgp *'`

sniff 节点在线抓 BGP。可自行查看：
`docker exec <sniff> tshark -r /tmp/bgp.pcap -Y 'bgp.type==1 && ip.src==10.1.12.1' -T fields -e bgp.open.holdtime`

按 Enter 验证；按 `f` 重新注入故障。
