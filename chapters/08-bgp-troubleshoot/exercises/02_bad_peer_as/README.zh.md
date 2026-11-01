# 02_bad_peer_as

先看现象：`edge` 的 eBGP 会话反复建立又断，始终到不了 Established。对端 `ext` 发回 NOTIFICATION，日志里写着 Bad Peer AS。

## 问题在哪

TCP 179 已经通了，双方也开始交换 OPEN。`edge` 在 OPEN 里报自己的 AS 65001，可 `ext` 给这个邻居配的 `remote-as` 是 65099。

AS 对不上，`ext` 用 OPEN Message Error（码 2，子码 2）拒绝，然后关闭会话。`edge` 再重试，还是同一个结果。

## 抓包或观察

在 `sniff` 上读抓包，直接看 NOTIFICATION 的错误码：

```sh
docker exec <sniff> tshark -r /tmp/bgp.pcap -Y 'bgp.type==3' -T fields -e bgp.notify.major_error -e bgp.notify.minor_error_open
```

应该看到 major 2、minor 2，对应 OPEN Message Error / Bad Peer AS。

## 动手修

在 `ext` 上把 `remote-as` 改成 `edge` 的真实 AS `65001`，再重置会话：

```sh
docker exec <ext> vtysh -c 'conf t' -c 'router bgp 65002' -c 'neighbor 10.1.12.1 remote-as 65001' -c 'end' -c 'clear bgp *'
```

按 Enter 验证。想重新注入故障，按 `f`。
