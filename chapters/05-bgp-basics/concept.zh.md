# BGP 入门——会话建立

## 场景

两个由不同运营商维护的网络需要交换路由。各自管理自己的设备，互不信任对方的 IGP。
它们约定在一段点对点链路上使用 BGP。

## 术语

- **BGP（Border Gateway Protocol，边界网关协议）**：在 AS 之间交换路由的路由协议。
- **自治系统（Autonomous System，AS）**：由单一管理机构维护、以 AS 号标识的网络（例如 65001）。
- **IGP（Interior Gateway Protocol，内部网关协议）**：单个运营商在自己网络内运行的路由协议（如 OSPF），不在不同 AS 之间交换。
- **对等体（peer，邻居）**：BGP 会话另一端的路由器。
- **eBGP**：两个不同 AS 之间的 BGP 会话。
- **有限状态机（Finite State Machine，FSM）**：BGP 会话依次经历的固定状态集合，如 `Idle`、`Connect`、`Active`、`OpenSent`、`OpenConfirm`、`Established`。
- **OPEN**：第一条 BGP 报文，用于协商参数。
- **KEEPALIVE**：周期性发送、用于确认会话仍然存活的消息。
- **NOTIFICATION**：报告错误并关闭会话的消息。
- **Hold Time**：在对端被判失效前，允许没有收到 KEEPALIVE 或 UPDATE 的最长时间；在 OPEN 中协商。

## 痛点

不同 AS 的路由器不共享 IGP，无法经它学到彼此的前缀。没有会话就没有路径，两个网络始终被隔离。

## 为什么直觉方案不行

用一条指向邻居的静态路由只对那一个前缀有效，既不可扩展，也不会对故障作出响应。
BGP 用 KEEPALIVE 维持会话、在对端消失时拆除会话，这是静态路由做不到的。

## 机制

BGP 跑在 TCP 179 端口上。会话沿 FSM 前进：TCP 建立后本端发出 OPEN；对端以它的 OPEN 回应；
双方各自发送 KEEPALIVE 后进入 `Established`。对端 AS（remote AS）不匹配的会话会被 NOTIFICATION（"Bad Peer AS"）拒绝。
OPEN 携带：

```
Version=4 | My AS | Hold Time | BGP Identifier | Optional Parameters (capabilities)
```

## 配置与查看

在 r1 上：
```
vtysh -c 'show bgp summary'
vtysh -c 'show bgp summary json'
```

在 sniffer 上观察线路上的 OPEN：
```
tcpdump -i any -w /tmp/bgp.pcap tcp port 179
tshark -r /tmp/bgp.pcap -Y 'bgp.type==1' -T fields -e bgp.open.myas -e bgp.open.holdtime -e bgp.open.identifier
```

## 常见问题

- 邻居一直达不到 `Established`，先查哪个字段？期望的 `remote-as` 必须与对端实际 AS 一致；不匹配会报 "Bad Peer AS"。
- 为什么 KEEPALIVE 要短于 Hold Time？整整一个 Hold Time 收不到 KEEPALIVE，对端就会判定会话失效（Hold Timer Expired）。
- 为什么改计时器要重置会话？计时器在 OPEN 中协商，只对新会话生效。
