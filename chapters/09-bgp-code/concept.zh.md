# 用 C 写一个最小 BGP speaker

## 先看现象

`r1` 上跑着 FRR。敲一句 `show bgp summary`，邻居那一行的状态是 `Established`；再敲 `show bgp ipv4 unicast`，表里躺着几条学来的前缀。看上去这东西很重：TCP、状态机、路径属性、下一跳解析，一层套一层。

可它底下就是一条普通 TCP 连接，两端按固定格式互发字节。字节的位置、长度、字节序，一个都不能挪。

那问题就来了：不装 BIRD，也不用 GoBGP，自己写一个几百行的 C 程序，连上 `r1` 的 179 端口，能不能让它把我当成 AS 65001 的邻居，把状态推到 Established，再收下我报的一条 `192.0.2.0/24`？

这一章就做这件事。你要写的不是一整个 BGP，而是刚好够握手、够通告一条路由的那部分。

## 问题在哪

最直觉的做法是：TCP `connect()` 成功，往 socket 里写一句 hello。`r1` 不会理你，几秒后把连接关掉，`show bgp summary` 里那行还停在 `Active`。

原因不复杂。BGP 对端在 TCP 建链之后有自己的节奏：双方各发一条 OPEN（开局那条报文），再各回一条 KEEPALIVE（只报个平安）。你少发一条，或者长度字段算错两个字节，对端就停在半路，或者直接 reset。

麻烦的是它不会告诉你哪一字节错了。你看到的只有“连不上”。

所以这件事的难点不在协议多复杂，而在字节要拼对：字段顺序、大端字节序、长度里算不算头部。

## 先把术语说清楚

- **BGP 报文（message）**：两端在 TCP 连接里交换的数据单元，每条都以 19 字节的固定头开始。
- **报文头（message header）**：Marker、Length、Type 三段，长度固定 19 字节。
- **Marker**：头部前 16 字节，全部填 `0xFF`。早期拿它做报文同步，现在只在兼容性检查里还留着。
- **OPEN**：TCP 建链后双方发的第一条报文，用来报自己的 AS 号、Hold Time 和 BGP Identifier。
- **KEEPALIVE**：只有报文头、没有正文，作用就是告诉对端“我还活着”。
- **Hold Time**：双方在 OPEN 里各报一个值，取小的那个作为协商结果。超过这个时间收不到任何报文，对端就认为连接死了。
- **UPDATE**：通告路由的报文，里面放路径属性和前缀。
- **NLRI（Network Layer Reachability Information）**：UPDATE 里真正要通告的前缀，比如 `192.0.2.0/24`。
- **路径属性（path attribute）**：跟着 NLRI 一起走的元信息。这次至少要放 ORIGIN、AS_PATH、NEXT_HOP 三个。
- **FSM（finite state machine，有限状态机）**：BGP 会话的状态流转，从 Idle 一路走到 Established。
- **Established**：握手完成、可以互发 UPDATE 的状态。`show bgp summary` 里看到的就是它。

## 机制：一条连接，四种报文

### 报文头：19 个字节，位置全固定

每条报文都从这 19 字节开始：16 字节 Marker，2 字节 Length，1 字节 Type。

Length 算的是整条报文，把这 19 字节头也算进去。所以 KEEPALIVE 的 Length 就是 19，不是 0。Type 里，1 是 OPEN，2 是 UPDATE，3 是 NOTIFICATION，4 是 KEEPALIVE。NOTIFICATION 用来报错拆链，这次用不到，但抓包时会看到对端发过来。

### OPEN：29 字节，一个字段都省不掉

你发出去的 OPEN 长这样，偏移量从 0 开始：

```
offset  size  field
0       16    Marker (0xFF x16)
16      2     Length = 29
18      1     Type = 1
19      1     Version = 4
20      2     My AS = 65001
22      2     Hold Time = 90
24      4     BGP Identifier = 10.1.12.1
28      1     Optional Parameters Length = 0
```

最后那个可选参数长度写 0，表示后面没有 capabilities。真实路由器会在这里塞 MP-BGP、四字节 AS 号这些能力协商，我们不需要。

算术要对上：19 字节头加 10 字节正文等于 29，所以 Length 填 29，不是 10，也不是 19。

### KEEPALIVE：一条没有正文的报文

19 字节，Marker 全 `0xFF`，Length 19，Type 4。就这些。

它为什么必须存在？因为 Hold Time 是双方约好的。这里 OPEN 报 90 秒，协商下来就是 90 秒。90 秒内对端收不到你任何报文，它会当你已经挂了，发 NOTIFICATION 拆链。所以推荐每 hold/3，也就是 30 秒发一次。KEEPALIVE 很便宜，19 个字节而已。

### UPDATE：属性在前，前缀在后

UPDATE 的正文分四段：

```
Withdrawn Routes Length(2) | Withdrawn Routes | Total Path Attribute Length(2) | Path Attributes | NLRI
```

这次不撤路由，所以前两段都写 0。属性段要放三个：

- **ORIGIN**：这条路由从哪来。填 0，表示 IGP。
- **AS_PATH**：路由经过哪些 AS。这里只有一段 AS_SEQUENCE，里面一个 AS 号：65001。
- **NEXT_HOP**：下一跳地址，填 `10.1.12.1`。

每个属性都是“标志位 1 字节、类型 1 字节、长度 1 字节、值”的结构。NEXT_HOP 的值是 4 字节 IP，长度就写 4。AS_PATH 的值里还要再嵌一层：段类型 1 字节、段里 AS 的个数 1 字节、然后每个 AS 2 字节。

最后是 NLRI。前缀的编码不是“IP 加掩码长度”，而是“掩码长度 1 字节，后面跟前缀本身，只写够用的那几个字节”。`192.0.2.0/24` 就是 `0x18`（24）加 `192 0 2` 三个字节，一共 4 字节。

### NEXT_HOP 为什么不能随便填

BGP 只负责告诉你“`192.0.2.0/24` 在那边”，不负责告诉你怎么走过去。怎么走要看 NEXT_HOP，`r1` 会拿它去查自己的路由表。

填 `10.1.12.1`，那是 speaker 在链路上的地址，`r1` 有一条直连路由，下一跳立刻可达。填一个 `r1` 不认识的地址，路由能进 BGP 表，`show bgp ipv4 unicast` 里也看得到，但进不了内核转发表。结果是路由数对得上，ping 不通。

### 会话怎么走到 Established

顺序是这样，一步都不能省：

1. speaker 主动 `connect()` 到 `r1:179`。
2. speaker 发 OPEN。
3. `r1` 回它自己的 OPEN。
4. speaker 读掉这条 OPEN，发 KEEPALIVE。
5. `r1` 回 KEEPALIVE，双方进入 Established。
6. speaker 发 UPDATE，`r1` 学到前缀。

这个练习里，第 4 步之后你其实可以不读入向报文，因为后面对端没有需要你响应的东西。但握手阶段把对端 OPEN 读掉是个好习惯，接收缓冲不会越堆越多。一个完整的 speaker 还会校验入向报文类型、按对端 OPEN 里的 Hold Time 重算发送间隔、出错时回 NOTIFICATION。这些都不在本次范围内。

## 动手：三个拼报文的函数，加一段时序

打开 `src/main.c`。TCP 连接、`send_all`、`recv_message` 都已经写好了，`put16`、`put32` 也在，字节序的坑别人替你填过。你要补三个函数，再把 `main` 的流程接起来：

- `build_open(buf, my_as, hold, rid)`：拼 29 字节，返回写进去多少字节。
- `build_keepalive(buf)`：拼 19 字节。
- `build_update(buf, nexthop, my_as)`：报文头、两个长度为 0 的段、三个属性、一条 NLRI，按顺序摆好。

所有多字节字段都走大端。在 x86 上直接把 `uint16_t` 拷进缓冲区，对端读到的就是反的字节。

写完把文件第一行的 `// I AM NOT DONE` 删掉。断言先看这一行还在不在，然后才看会话。

## 配好了看什么

在 `r1` 上：

```sh
vtysh -c 'show bgp summary'
vtysh -c 'show bgp ipv4 unicast'
```

要看三件事：邻居状态是 `Established`；表里有 `192.0.2.0/24`，下一跳 `10.1.12.1`；路由总数是 1。

你自己的日志在 speaker 节点：

```sh
cat /tmp/bgp.log
```

想直接看字节，就在 speaker 上抓 179 端口，`-X` 会把内容按十六进制打出来。OPEN 应该是 29 字节，开头 16 个 `ff`；KEEPALIVE 19 字节，短得一眼就能认出来。

```sh
tcpdump -i eth1 -nn -X port 179
```

## 几个常见坑

### 状态一直停在 Active

TCP 没连上。先确认 speaker 进程在跑，再确认两边地址在 `10.1.12.0/30` 里。程序启动参数是 `10.1.12.2`，填错就直接连不上，日志里只有一句 connect 失败。

### 连上了，几秒后又断

握手少了一步。OPEN 发完没发 KEEPALIVE，或者 KEEPALIVE 的 Type 写成了别的。90 秒一到，`r1` 就拆链。抓包能看出来：你这边只有一条 OPEN，对端回了两条报文。

### Established，但路由表里没有前缀

看 UPDATE 的 Total Path Attribute Length。写小了属性会被截断，写大了会把 NLRI 也吞进属性段，对端解析失败，整条 UPDATE 被丢掉。

### 路由在 BGP 表里，ping 还是不通

看 NEXT_HOP，必须是 `10.1.12.1`。再看 `show bgp ipv4 unicast` 里那条路由前面的 `*`：它表示这条路由有效，下一跳能解析。看不到 `*`，就是下一跳不可达，内核里也不会装这条路由。

### 顺手多报了一条前缀

断言只认路由总数等于 1。多报一条，第三个断言就挂。这次只发 `192.0.2.0/24`。

### marker 能不能随便填

不能。现在的 FRR 会检查这 16 个字节，填错直接丢报文。真正用来切分报文的是 Length，Marker 只是早期留下的固定填充值。

### 为什么拓扑里要关掉 eBGP 策略要求

FRR 默认按 RFC 8212 要求 eBGP 邻居配入向策略，没有策略就不装路由。拓扑里已经写了 `no bgp ebgp-requires-policy`，所以你发过去的前缀能直接进表。自己搭环境时这一条最容易漏，表现出来就是会话 Established、路由一条没有。
