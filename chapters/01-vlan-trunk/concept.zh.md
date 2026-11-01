# VLAN 与 Trunk：交换机到底在背后做了什么

## 先看一个真实的小网络

一个小办公室，一台二层交换机，24 台机器全在同一个网段。平时相安无事。后来有人接了一台测试平台进来，广播特别多。没过多久，整张网开始变慢，吞吐量掉得厉害。

这就是典型的“一个广播域装下了所有人”。在没划 VLAN 的扁平网络里，整个局域网就是一个大广播域。交换机碰到广播帧，或者目的 MAC 还不认识的单播帧，默认就是往所有端口泛洪。只要有一台设备话多，所有人都得跟着听。

## 那，再加一台交换机行不行？

不行。再买一台级联上去，只是把同一个广播域放大了一圈，问题还在。那为了冗余再加一条线？如果没开 STP，两条线直接成环，广播风暴马上就来。

所以问题不是“交换机不够”，而是“大家还在同一个广播域里”。

## VLAN：把一个大广播域切成几个小的

VLAN 就是干这个的：在同一个物理网络上，切出多个逻辑广播域。不同 VLAN 的端口在二层互相隔离，谁也看不到谁的广播。

你可以把它想成把一间大办公室隔成几个小房间：墙还是那些墙，交换机还是那台交换机，但每个房间里的声音传不出去。

## 几个绕不开的术语

- **广播域（Broadcast Domain）**：广播帧能扩散到的端口范围。交换机收到广播帧或未知单播帧时，会往这个范围里除入口外的所有端口泛洪。
- **VLAN（虚拟局域网）**：用逻辑方式切出来的广播域。不同 VLAN 的端口在二层互相隔离。
- **802.1Q Tag**：插在源 MAC 和 EtherType 之间的 4 字节字段，里面最关键是 12 位 VLAN ID（可用范围 1~4094）。
- **PVID（Port VLAN ID）**：端口的默认 VLAN ID。进入端口的无标签（Untagged）帧，就按它来分 VLAN。
- **Access 端口**：一般接电脑、打印机这类终端，只在一个 VLAN 里。发出去的帧不带 802.1Q 标签。
- **Trunk 端口**：一般用在交换机之间，或者交换机接路由器、服务器。一条链路可以同时让多个 VLAN 带着标签通过。
- **Native VLAN**：Trunk 上唯一一个不打标签、直接裸传的 VLAN。

## 交换机到底怎么判断一帧是哪个 VLAN 的？

交换机看的是帧里的字节。每收到一帧，它都得先回答一个问题：这帧是哪个广播域的？不同端口，答案不一样。

### Access 口：主机不打标签，交换机来补

普通电脑的网卡默认不认识 802.1Q：不会打标签，也不会拆标签。收到带标签的帧，它会把 802.1Q 的 TPID（0x8100）当成未知 EtherType，直接丢掉。

所以 Access 口发给终端的，必须是不带标签的普通帧。可交换机内部转发又得知道这帧是哪个 VLAN 的，怎么办？靠 PVID。终端发出的无标签帧一进端口，交换机就给它打上这个端口的 PVID，让它在对应的 VLAN 里走。

### Trunk 口：一条线跑多个 VLAN，只能靠标签

两台交换机之间只有一条物理链路，却要同时跑好几个 VLAN。帧上要是没标签，对端根本分不清它是 VLAN 10 还是 VLAN 20，二层隔离就没了。

所以 Trunk 发给对端的非 Native VLAN 帧，都要封装 802.1Q 标签。在这条共享链路上，标签就是这帧唯一的二层身份。

### Native VLAN：唯一不打标签的那个，也最容易出事

为了兼容 CDP、LLDP、STP 这些协议报文，或者一些不会打标签的老设备，802.1Q 允许 Trunk 上留一个特殊的 Native VLAN。这个 VLAN 的帧在 Trunk 上不打标签，直接裸传。

但裸帧自己不带 VLAN 信息。对端收到后，只能按本地端口的 PVID 来归类。两端 Native VLAN 一旦对不上，流量就会跑到别的 VLAN，或者被悄悄丢掉。

## 动手配一下

在 Linux 网桥上，把 `br0` 建起来，再把几个口挂上去：

```sh
# 建一个支持 VLAN 过滤的 Linux 网桥并启用
ip link add br0 type bridge vlan_filtering 1 && ip link set br0 up
ip link set eth1 master br0 && ip link set eth2 master br0 && ip link set eth3 master br0

# eth1 当 Access 口：只在 VLAN 10 里，进出都不打标签
bridge vlan add dev eth1 vid 10 pvid untagged

# eth3 当 Trunk 口：VLAN 10 带标签通过，VLAN 20 设为 Native VLAN
bridge vlan add dev eth3 vid 10
bridge vlan add dev eth3 vid 20 pvid untagged

# 看看每个端口的 VLAN、PVID，以及出方向打不打标签
bridge vlan show
```

## 抓个包，看看标签差在哪

配完别急着走，抓包看一眼最直观：

```sh
# Access 链路：普通以太网帧，没有 802.1Q 头
tcpdump -i eth1 -e -nn

# Trunk 链路：VLAN 10 会显示 "vlan 10"，Native VLAN 20 仍然不带标签
tcpdump -i eth3 -e -nn
```

## 几个常见坑

### IP 同网段，为什么还是不通？

先看两端 Access 口的 PVID 是不是一样。裸帧被分到不同 VLAN，广播和单播都过不去。

### 跨交换机同一个 VLAN 不通？

看看中间 Trunk 口有没有放行这个 VLAN。没放行的 VLAN，报文进出时会被直接丢掉。

### Trunk 两端 Native VLAN 不一致会怎样？

裸帧归哪个 VLAN，完全由接收端口的 PVID 决定。两端配得不一样，流量就会跑到错误的 VLAN 里，而且很难发现。

### 主机能直接接 Trunk 口吗？

可以。只要主机（Linux、ESXi 都行）建一个 802.1Q 子接口，比如 `eth0.10`，自己打标签，而且这个 VLAN 在对端 Trunk 的放行列表里。
