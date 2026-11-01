# BGP 报文：UPDATE 与 NOTIFICATION

## 会话 Established，路由却没来

两个运营商刚把 eBGP 会话打通。AS 65001 的 r1 和 AS 65002 的 r2 隔着 sniff 相连，`show bgp summary` 里邻居状态是 Established，uptime 一秒秒在涨。

可 r2 的路由表里没有 192.0.2.0/24。r1 明明写了 `network 192.0.2.0/24`，`pfxSnt` 却一直是 0。

值班的人开始猜：链路断了？前缀写错了？还是被策略挡了？

## 先把问题拆开

会话起来，只说明两件事：TCP 179 通了，OPEN 里的参数谈拢了。它不保证路由已经发出去。

于是排障可以按三个问题走：

- 邻居真的 Established 吗？看 `show bgp summary`，别只看 ping。
- 本地有没有这条路由？看 `show bgp ipv4 unicast`。
- 如果本地有、对端没有，就去看链路上的 UPDATE。前缀到底有没有装进报文？

这三个问题对应三种完全不同的修法。顺序反了，就容易在错误的地方改配置。

## 几个绕不开的术语

- **BGP 报文头部（message header）**：每条报文开头固定的 19 字节。前 16 字节是 marker，全为 1；接着 2 字节 length，把头部一起算进去；最后 1 字节 type，说明这是哪种报文。length 的合法范围是 19 到 4096。
- **OPEN（类型 1）**：会话建立时的第一条报文，用来协商版本、AS 号、Hold Time 这些参数。
- **UPDATE（类型 2）**：真正承载路由的报文。里面有三块内容：要撤销的前缀、路径属性、NLRI。
- **NOTIFICATION（类型 3）**：出错时发给对端，带上错误码，发完就关会话。
- **KEEPALIVE（类型 4）**：只有 19 字节头部，没有正文。它只做一件事，告诉对端“我还在”。
- **NLRI（Network Layer Reachability Information）**：UPDATE 里通告的前缀列表，也就是“我能到这些网段”。
- **路径属性（path attribute）**：UPDATE 里带类型和标志的字段。ORIGIN 说明路由从哪来，AS_PATH 记录走过的 AS，NEXT_HOP 给出下一跳。
- **AS_PATH**：一条路由经过的 AS 有序列表。每经过一个 AS，就追加一次它的 AS 号。
- **Route-map**：FRR 里的策略工具。它可以按前缀匹配，再修改属性或直接过滤；挂在出向，就作用在发出去的 UPDATE 上。

## 一条 UPDATE 里装了什么

先看布局：

```
Marker(16, all ones) | Length(2) | Type(1)          <- header
Withdrawn Routes Length(2) | Withdrawn Routes | Total Path Attribute Length(2) | Path Attributes | NLRI
```

收到一条 UPDATE，读取顺序是这样的：先读报文头部，拿到总长度和类型；再读 2 字节的撤销路由长度，跳过撤销列表；接着读 2 字节的属性总长度，取出路径属性；剩下的字节就是 NLRI。

所以“前缀在哪”这个问题有明确答案：不在头部，也不在 AS_PATH 里，它在最后的 NLRI。AS_PATH 只是记录这条前缀走过哪些 AS。

## 会话是好的，为什么 pfxSnt 是 0

FRR 对 eBGP 有一条默认规则，叫 `ebgp-requires-policy`。意思是：没有策略，就不自动通告，也不自动接收。

这条规则不影响 OPEN 和 KEEPALIVE，所以会话照样能到 Established。但 `show bgp summary` 会露出马脚：邻居的 `peerState` 显示 `Policy`，`pfxSnt` 停在 0。

换句话说，“邻居 Established”和“路由在流动”是两件事。前者只证明会话通了，后者还要过策略这一关。

要放开有两条路。写一条明确的出向 route-map，或者临时执行 `no bgp ebgp-requires-policy`。改完还得 `clear bgp *`，因为已经发过的 UPDATE 不会因为你改了配置就自动重发。

## 主动重置，为什么会抓到 NOTIFICATION

`clear bgp *` 不是悄悄断开。FRR 在关会话之前，会先发一条 NOTIFICATION，错误码 6，名字叫 Cease，然后才关 TCP。

抓包里看到 type 3、major error 6，不用紧张，这是本端主动拆链。真正要分清的是：这条 NOTIFICATION 是对端报错，还是自己重置带出来的。

NOTIFICATION 的常见错误码不多：

- 1，报文头部错误，比如 marker 不对、length 越界。
- 2，OPEN 报文错误，比如对端 AS 号和本地配置对不上。
- 3，UPDATE 报文错误，比如路径属性或 NLRI 格式不对。
- 4，Hold Time 到期，说明一段时间没收到 KEEPALIVE 或 UPDATE。
- 5，状态机错误，收到了当前状态不该处理的事件。
- 6，Cease，会话被主动关闭。

## 动手看一次

在 r1 上看会话和本地路由：

```sh
vtysh -c 'show bgp summary'
vtysh -c 'show bgp ipv4 unicast'
```

第一条命令回答“邻居通不通、发了多少前缀”；第二条回答“本地 BGP 表里有没有这条前缀”。

再到 sniff 上抓包。它桥接在 r1 和 r2 之间，179 端口的报文都会经过它：

```sh
tcpdump -i any -w /tmp/bgp.pcap tcp port 179
tshark -r /tmp/bgp.pcap -Y 'bgp.type==2' -T fields -e bgp.update.path_attribute.type_code
tshark -r /tmp/bgp.pcap -Y 'bgp.type==2' -T fields -e bgp.update.path_attribute.as_path_segment.as4 -e bgp.nlri_prefix
tshark -r /tmp/bgp.pcap -Y 'bgp.type==3' -T fields -e bgp.notify.major_error
```

第一条只抓包，不解析。后面三条分别回答：UPDATE 里有哪些路径属性、AS_PATH 和 NLRI 各是什么、NOTIFICATION 的错误码是多少。

## 几个常见坑

### 邻居 Established，前缀就是不来

先看 `peerState`。显示 `Policy`，就是 `ebgp-requires-policy` 在拦。加策略，或者先关掉它，再 `clear bgp *`。

### 改了 route-map，抓包还是旧 AS_PATH

配置改了不等于报文重发。UPDATE 要等下一次会话建立或重置才带新属性。`clear bgp *` 之后再抓。

### AS_PATH 里的 65001 怎么数不对

本端发布前缀时会写一次自己的 AS。再 prepend 两次，对端看到的就是三个 65001。prepend 改的是出向属性，本地路由表里的 AS_PATH 不会跟着变。

### 抓到 NOTIFICATION 就以为链路故障

先看错误码。6 是 Cease，主动重置就会有；1 到 5 才更像是真出了问题。再看方向，是本端发的还是对端发的。
