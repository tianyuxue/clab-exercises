# BGP 入门：一条 eBGP 会话是怎么建起来的

## 先看现象

两家运营商各管一张网，中间拉了一根点对点链路。你在 r1 上配好地址，写下邻居和 remote-as；在 r2 上也照做。按说接下来就该看到 Established，路由表里慢慢出现对端前缀。

结果 `show bgp summary` 刷了好几遍，邻居那一列还是 Active。没有 Established，就没有 UPDATE，两边的路由一条也过不来。

## 问题在哪：静态路由为什么顶不住

最省事的办法是写静态路由：比如要去 10.2.0.0/16，下一跳就指 10.1.12.2。前缀少、拓扑不变时，这样确实能用。

可两家网络之间的前缀成千上万，还会随时增删。静态路由不会跟着变，对端挂了也不会撤回，出了故障只能靠人发现。BGP 换了个做法：两台路由器先建一条 TCP 会话，把对方当对等体（peer）。会话活着，才交换路由；会话断了，从这条会话学来的路由一起撤掉。

## 几个绕不开的术语

- **BGP（Border Gateway Protocol，边界网关协议）**：在不同 AS 之间交换路由的协议。你可以把它想成两家运营商之间的谈判桌。
- **自治系统（Autonomous System，AS）**：一个管理机构下的一张网络，用 AS 号标识，比如 65001。
- **IGP（Interior Gateway Protocol，内部网关协议）**：运营商在自家网内跑的路由协议，比如 OSPF。它只服务自己，不跨 AS 交换。
- **对等体（peer，也叫邻居）**：BGP 会话另一端的路由器。
- **eBGP**：跨 AS 建立的 BGP 会话。本章的 r1 和 r2 就是 eBGP。
- **有限状态机（Finite State Machine，FSM）**：会话要依次走过的一组状态，包括 `Idle`、`Connect`、`Active`、`OpenSent`、`OpenConfirm`、`Established`。
- **OPEN**：TCP 建好后的第一条 BGP 报文，双方拿它谈参数。
- **KEEPALIVE**：定时发送的保活报文，意思是“我还在”。
- **NOTIFICATION**：报告错误并关闭会话的报文。
- **UPDATE**：真正携带路由的报文，前缀放在 NLRI（Network Layer Reachability Information，网络层可达信息）里。
- **Hold Time**：多久收不到 KEEPALIVE 或 UPDATE，就认定对端失联。这个值在 OPEN 里协商。
- **BGP Identifier**：OPEN 里 4 字节的发送方标识，通常取 router-id。
- **能力（Capabilities，放在 Optional Parameters 里）**：OPEN 的可选字段，用来谈地址族等扩展功能。

## 会话怎么一步步起来

BGP 自己不找邻居，它先让 TCP 干活。两端在 179 端口上连起来，才有后面的 OPEN、KEEPALIVE 和 UPDATE。

会话沿状态机往前走：

- `Idle`：起点。没有 Start 事件就不动，也不占资源。
- `Connect`：本端正在发 TCP 连接。
- `Active`：TCP 没连上，转成被动等对端来连。ConnectRetry 计时器到期后，再主动试一次，重新进入 `Connect`。
- `OpenSent`：TCP 通了，本端 OPEN 已经发出，等对端的 OPEN。
- `OpenConfirm`：对端 OPEN 收下，等对端的 KEEPALIVE。
- `Established`：双方的 KEEPALIVE 都收到，会话可用，可以交换 UPDATE。

这里最容易误会的是 `Active`。它不代表“已经活了”，恰恰相反，会话还卡在 TCP 之前。看到 Active，先查地址通不通、179 端口有没有被拦，再看配置。

## OPEN 里装了什么

TCP 一通，双方各自发出 OPEN。报文的字段顺序是：

```
Version=4 | My AS | Hold Time | BGP Identifier | Optional Parameters (capabilities)
```

Version 固定是 4；My AS 告诉对端“我在哪个 AS”；Hold Time 提议保活窗口；BGP Identifier 是 4 字节身份，通常取 router-id；Optional Parameters 里放 Capabilities，比如支持哪些地址族。

对端收到 OPEN 会先做几项检查，其中一项是 AS。假设 r2 配的 remote-as 是 65099，而 r1 的 OPEN 里 My AS 是 65001，r2 会回一条 NOTIFICATION，错误码是 Bad Peer AS，然后关掉 TCP。r1 只能重连，再被拒。

Hold Time 由双方各提一个，最后取小的。180 和 9 谈完就是 9。RFC 4271 建议 KEEPALIVE 间隔取 Hold Time 的三分之一：Hold Time 180 秒时每 60 秒发一次，Hold Time 9 秒时就是 3 秒。

Hold Time 为 0 是特例：双方不再启动保活计时器，也不发 KEEPALIVE。因为协商取最小值，只要一端提 0，结果就是 0。

计时器只在 OPEN 里谈一次。改完配置，旧会话还按旧值跑；要让新值生效，得把会话拆掉重建。

## 动手：抓一条 OPEN 出来

先看会话状态。在 r1 上：

```sh
vtysh -c 'show bgp summary'
vtysh -c 'show bgp summary json'
```

邻居后面那一列是 State/PfxRcd。Established 后面跟数字，表示从这条会话学到的前缀数；显示 Active 或 Connect，说明会话还没起来。

再到 sniff 上抓 179 端口：

```sh
tcpdump -i any -w /tmp/bgp.pcap tcp port 179
tshark -r /tmp/bgp.pcap -Y 'bgp.type==1' -T fields -e bgp.open.myas -e bgp.open.holdtime -e bgp.open.identifier
```

默认计时器下，r1 的 OPEN 会打出 `65001 180 10.1.12.1`。把 Hold Time 改成 9 秒并重置会话后，同一位置变成 `65001 9 10.1.12.1`。

## 几个常见坑

### 邻居一直停在 Active

先 ping 对端地址，再看 TCP 179 通不通。地址、回程路由、ACL 任何一处断了，会话都走不到 OPEN。TCP 通了还在 Active 和 Connect 之间循环，就去核对 remote-as 和更新源地址。

### 日志里报 Bad Peer AS

对端 OPEN 里的 My AS 和你配的 remote-as 对不上。改自己这边的 remote-as，别去改对端的 AS 号。

### KEEPALIVE 比 Hold Time 还长

整整一个 Hold Time 收不到 KEEPALIVE 或 UPDATE，本端就发 NOTIFICATION，错误码 Hold Timer Expired（4），会话回到 Idle。KEEPALIVE 必须短于 Hold Time，工程上通常取三分之一。

### 改完计时器，抓包还是老值

计时器在 OPEN 里协商，只对新会话生效。`clear bgp *` 之后重新建会话，才能看到新值。

### 两端 Hold Time 不一样，听谁的

听小的。180 和 9 谈完是 9。

### 会话起来了，路由却没有

FRR 默认要求 eBGP 配策略。本章脚本用 `no bgp ebgp-requires-policy` 关掉了这项检查，只关注会话本身。生产环境不要照抄，应该写 route-map 控制收发的路由。
