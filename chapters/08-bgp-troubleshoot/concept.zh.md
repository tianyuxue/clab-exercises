# BGP 排错

## 场景

一条原本可用的 BGP 会话断了，或某条路由不见了。运维者只有几分钟，要在若干相似
的原因中找出真正的那一个。

## 术语

- **Active**：状态机中持续尝试连接对端的状态；TCP 连接失败。
- **Bad Peer AS**：当对端 AS 号与配置不符时发出的 OPEN Message Error（码 2，子码 2）。
- **NEXT_HOP**：UPDATE 告诉接收方转发所用地址；iBGP 默认保留 eBGP 的下一跳，除非被改写。
- **next-hop-self**：一条 iBGP 设置，把 NEXT_HOP 改写为通告路由器自己的地址。
- **NOTIFICATION**：报告错误并关闭会话的报文。

## 痛点

"会话断了"和"路由没了"都不是诊断。它们各自对应不同的状态或属性，修好一个对另一个
毫无帮助。

## 为什么直觉方案不行

当邻居地址、remote AS 或下一跳可达性有误时，重置会话或重启都无济于事；同样的故障
会再次出现。

## 机制

先看状态机状态：停在 `Active` 表示对端不可达（地址或路由问题）；到达 `OpenSent` 后
重置并伴随 NOTIFICATION `Bad Peer AS` 表示 remote AS 不匹配。"学到却未安装"的路由，
通常是 `NEXT_HOP` 无法解析——在 iBGP 边界用 `next-hop-self` 修复。

## 配置与查看

在路由器上：
```
vtysh -c 'show bgp summary'
vtysh -c 'show bgp ipv4 unicast'
```

在 sniffer 上读 NOTIFICATION：
```
tshark -r /tmp/bgp.pcap -Y 'bgp.type==3' -T fields -e bgp.notify.major_error -e bgp.notify.minor_error_open
```

## 常见问题

- 邻居停在 Active，先查什么？查邻居地址以及到它是否有路由。
- 对端在 OpenSent 后立刻重置，为什么？它的 remote-as 与我们的 AS 不符；找 NOTIFICATION Bad Peer AS。
- iBGP 路由学到了却没安装，为什么？它的 NEXT_HOP 不可达；在边界路由器上设 `next-hop-self`。
