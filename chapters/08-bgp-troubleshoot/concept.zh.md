# BGP 排错：邻居停在 Active，路由却没装上

## 先看现场

一张很小的拓扑：`edge` 一边接外部路由器 `ext`，跑 eBGP；另一边接内部路由器 `core`，跑 iBGP。`ext` 把 `192.0.2.0/24` 通告进来，`edge` 再转给 `core`。这条链平时正常。

排错练习会在这张图上依次制造三个故障。

第一个，`edge` 的 eBGP 邻居一直显示 Active。第二个，会话能走到 OpenSent，但马上被 NOTIFICATION 打回。第三个，会话 Established 了，`core` 的 BGP 表里也能看到 `192.0.2.0/24`，路由表里却没有。

三个现象看起来都像“BGP 坏了”，修法却完全不同。这一章就沿着这三条线，把症状拆成可检查的状态和属性。

## 为什么 clear 和重启不解决问题

遇到会话不通，很多人的第一反应是 `clear bgp *`，不行就重启。可重置只是让状态机从头再走一遍。邻居地址写错、对端 AS 号不匹配、下一跳不可达，这些条件一个都没变，同样的故障很快会回来。

排错要先回答三个问题：TCP 连接建起来了吗？OPEN 交换成功了吗？路由学到了，为什么没进路由表？三个问题对应三个不同的观察点。

## 几个绕不开的术语

- **BGP 会话（session）**：两台路由器之间通过 TCP 179 建立的一条 BGP 连接，路由只在这条会话上交换。
- **iBGP**：同一个 AS（Autonomous System，自治系统）内的 BGP 会话。`edge` 和 `core` 都在 AS 65001，它们之间就是 iBGP。
- **eBGP**：不同 AS 之间的 BGP 会话。`edge`（AS 65001）和 `ext`（AS 65002）之间就是 eBGP。
- **OPEN**：建立会话时交换的第一种报文，用来协商 AS 号等参数。
- **UPDATE**：通告路由的报文，里面带前缀和 NEXT_HOP 等属性。
- **有限状态机（Finite State Machine，FSM）**：BGP 会话按固定顺序经过的状态集合，包括 `Idle`、`Connect`、`Active`、`OpenSent`、`OpenConfirm`、`Established`。
- **Active**：不是“会话正常”，而是路由器还在反复尝试连接对端。TCP 没建起来时，常常停在这里。
- **OpenSent**：TCP 已经通了，本端也发出了 OPEN，正在等对端的 OPEN。这个状态很短暂，出问题时往往只留下一行日志或一个报文。
- **NOTIFICATION**：BGP 用来报告错误并关闭会话的报文。错误码和子码会说明关闭原因。
- **Bad Peer AS**：OPEN Message Error 的一种，错误码 2，子码 2。对端发现 OPEN 里的 AS 号和本端配置的 `remote-as` 不一致时，会用它拒绝会话。
- **NEXT_HOP**：UPDATE 里告诉接收方“去这个前缀，先把包发给谁”的地址。这个地址必须能解析，路由才有资格参与选路。
- **next-hop-self**：iBGP 邻居上的一个设置。它让路由器在通告路由时，把 NEXT_HOP 改成自己的地址。
- **remote-as**：本端给邻居配置的期望 AS 号。它必须和对端真实使用的 AS 号一致。

## 三种症状，三种读法

### 一直 Active：TCP 都没建起来

先看第一条。`edge` 的 `eth2` 地址是 `10.1.12.1/30`，`ext` 的 `eth1` 是 `10.1.12.2/30`。可 `edge` 上配置的邻居地址却是 `10.1.12.9`。

这个地址不在链路网段里，`edge` 也没有到它的路由。TCP SYN 发不出去，BGP 连 OPEN 都送不到对端，FSM 只能在 Active 和 Connect 之间来回。

所以看到 Active，先别怀疑 BGP 协议本身。拿邻居地址和接口网段对一下，再确认到那个地址有没有路由。地址错了就改地址，路由缺了就补路由。

### OpenSent 后被 NOTIFICATION：AS 号对不上

第二条更绕一点。TCP 179 已经通了，双方开始交换 OPEN，说明地址和路由都没问题。可 `ext` 给这个邻居配的 `remote-as` 是 65099，`edge` 的真实 AS 是 65001。

`ext` 收到 OPEN，发现里面写的 AS 号和它期望的不一样，于是发出 NOTIFICATION：OPEN Message Error，码 2，子码 2，也就是 Bad Peer AS。会话随即关闭，`edge` 再重试，再被拒。

这类故障不能只看“会话断没断”，要看 NOTIFICATION 的错误码。抓 TCP 179 的包，把 major 和 minor 读出来，方向就很清楚：是谁拒绝，拒绝的理由是什么。

### Established 却没有路由：NEXT_HOP 不可达

第三条最容易骗人。`edge` 和 `core` 的 iBGP 会话已经 Established，`core` 的 BGP 表里也能看到 `192.0.2.0/24`，可路由表里没有，`ping 192.0.2.1` 也不通。

原因在 NEXT_HOP。`edge` 从 `ext` 学到这条路由时，下一跳是 `10.1.12.2`。它把路由转给 iBGP 邻居 `core` 时，默认保留这个下一跳，不会自动改成自己。

`core` 只有 `10.1.1.0/30` 的直连路由，到不了 `10.1.12.2`。BGP 认为这条路径无效，于是把它留在 BGP 表里，却不装进路由表。

常见修法是在 `edge` 的 iBGP 邻居上打开 `next-hop-self`，让通告带上的下一跳变成 `edge` 自己的 `10.1.1.1`。也可以让 `core` 真正有一条到 `10.1.12.2` 的路由；两种思路都是让下一跳可达，实验里用前者。

## 配置与查看

先看邻居状态：

```sh
vtysh -c 'show bgp summary'
vtysh -c 'show bgp ipv4 unicast'
```

第一条命令看每个邻居的状态和前缀数。邻居卡在 Active，前缀数通常是 0；到了 Established，才有前缀可谈。第二条命令看 BGP 表里的路径、下一跳和状态码。某条路由“学到了却没安装”，重点看它的 NEXT_HOP 能不能解析。

再看 NOTIFICATION：

```sh
tshark -r /tmp/bgp.pcap -Y 'bgp.type==3' -T fields -e bgp.notify.major_error -e bgp.notify.minor_error_open
```

输出里的 major 2、minor 2，就是 OPEN Message Error / Bad Peer AS。错误码对上了，再去查两端的 AS 配置，比盲改快得多。

## 一张排错顺序表

1. **邻居什么状态**：`show bgp summary`。Active 先查地址和到邻居的路由；OpenSent 反复重置，去抓 NOTIFICATION。
2. **OPEN 为什么被拒**：读错误码和子码，再对照两端的 `remote-as`。Bad Peer AS 就是 2/2。
3. **路由为什么没安装**：`show bgp ipv4 unicast` 看 NEXT_HOP 和路径状态；下一跳不可达，就在 iBGP 边界上做 `next-hop-self`，或者把下一跳的路由补上。
4. **最后才重置**：改完配置再 `clear bgp *`，让新参数生效。顺序反过来，只会把同一个故障重演一遍。

## 几个常见问题

### 邻居停在 Active，先查什么？

先查邻居地址和到它的路由。地址不在链路网段，或者没有去往它的路由，TCP 就建不起来，BGP 只能重试。

### 对端在 OpenSent 后立刻重置，为什么？

看 NOTIFICATION。最常见的是 `remote-as` 和对端真实 AS 不一致，错误码 2、子码 2，Bad Peer AS。把两端的 AS 号对齐，再重置会话。

### iBGP 路由学到了却没安装，为什么？

看 NEXT_HOP。iBGP 默认保留 eBGP 的下一跳，如果内部路由器到不了那个地址，路径就无效。典型修法是在边界路由器上设置 `next-hop-self`。

### 为什么不能只 clear？

`clear bgp *` 只重启会话，不修改邻居地址、AS 号或下一跳。根因还在，故障就会回来。
