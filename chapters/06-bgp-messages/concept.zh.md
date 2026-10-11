# BGP 报文——UPDATE 与 NOTIFICATION

## 场景

两个运营商已经有可用的 BGP 会话。现在他们需要让路由真正流通起来，并需要一种
方法在出问题时弄清原因。

## 术语

- **报文头部（Message header）**：每条报文固定的 19 字节前缀：16 字节 marker（全 1）、2 字节 length（含头部）、1 字节 type。
- **UPDATE**：类型 2；承载撤销路由、路径属性与 NLRI（通告的前缀）。
- **NOTIFICATION**：类型 3；报告错误并关闭会话。
- **KEEPALIVE**：类型 4；仅头部，用于确认会话存活。
- **NLRI（Network Layer Reachability Information）**：UPDATE 通告的前缀列表。
- **路径属性（Path attribute）**：UPDATE 中带类型与标志的字段，如 ORIGIN、AS_PATH、NEXT_HOP。
- **AS_PATH**：一条路由经过的 AS 有序列表。

## 痛点

当对端收不到某前缀时，不了解报文格式的运维者是盲的：是会话断了、被策略挡住，还是路由格式有误？

## 为什么直觉方案不行

当真正的原因是"根本没有发出路由"时，重启路由器或重新加 `network` 语句都无济于事。
必须看会话在做什么（策略状态），必要时还要看链路上的字节。

## 机制

会话 Established 之后，UPDATE 承载路由。每条 UPDATE 由报文头部起头，并携带
AS_PATH 等路径属性：

```
Marker(16, all ones) | Length(2) | Type(1)          <- header
Withdrawn Routes Length(2) | Withdrawn Routes | Total Path Attr Length(2) | Path Attributes | NLRI
```

FRR 的 eBGP 默认要求策略（`ebgp-requires-policy`）；没有策略时会话虽在，但 `pfxSnt` 保持 0。
拆链时 BGP 会发送 NOTIFICATION `Cease`（码 6）。

## 配置与查看

在 r1 上：
```
vtysh -c 'show bgp summary'
vtysh -c 'show bgp ipv4 unicast'
```

在 sniffer 上读链路上的报文：
```
tshark -r /tmp/bgp.pcap -Y 'bgp.type==2' -T fields -e bgp.update.path_attribute.type_code
tshark -r /tmp/bgp.pcap -Y 'bgp.type==2' -T fields -e bgp.update.path_attribute.as_path_segment.as4 -e bgp.nlri_prefix
tshark -r /tmp/bgp.pcap -Y 'bgp.type==3' -T fields -e bgp.notify.major_error
```

## 常见问题

- 邻居 Established 却不发前缀，为什么？FRR 的 `ebgp-requires-policy` 开着；加上 `no bgp ebgp-requires-policy` 或一条出向 route-map，然后 `clear bgp *`。
- 前缀在 UPDATE 的哪里？在 NLRI 字段（`bgp.nlri_prefix`）；AS_PATH 是路径属性（`...as_path_segment.as4`）。
- 为什么 `clear bgp *` 会产生 NOTIFICATION？主动拆链会在关闭前发送 `Cease`（码 6）。
