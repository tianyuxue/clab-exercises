# 链路聚合（LACP）：两根线怎么当一根用

## 先看现象

机房里一台服务器，单上行 1 Gbit/s，高峰期跑满。加一根线接到同一台交换机，灯亮了，带宽却没涨，监控里还多出一条环路告警。

于是把两根线捆成 `lag1`，两端都开 LACP。配置下去，`show lag` 却显示 `lag1` down，原因写着 `no-active-links`。两个口明明都是 up。

这是链路聚合最典型的一幕：物理层全绿，聚合层没谈拢。

## 问题在哪

先把几种“看起来能行”的做法排掉。

**插两根线，不做聚合。** 二层立刻成环，STP 会阻塞其中一条，带宽还是 1 Gbit/s。冗余有了，代价是收敛要等 STP，另一条线平时闲着。

**做静态 bond，不跑 LACP。** 链路能 up，可两端谁也不知道对方配得对不对。遇到半坏的链路，比如收光正常但丢包严重，它照样留在组里转发，流量照样被丢。

**两根线接到两台交换机。** 每台交换机都是独立的 LACP 伙伴，各有一个 System ID。服务器看到的是两个单链路捆绑，凑不成一个双链路捆绑。这条路得靠 MLAG 或 EVPN-MH。

那聚合靠什么把两根线变成一根？

## 几个绕不开的术语

- **LAG**（链路聚合组，Linux 上叫 bond，有些厂商叫 PortChannel）：多条物理链路拼出来的一个逻辑接口。IP、路由都配在这个逻辑口上。
- **成员（member）**：真正插着线的那条物理链路。它自己不配地址，只被 LAG 引用。
- **流哈希（flow hashing）**：交换机按报文头部字段算哈希，给每条流挑一个成员。同一条流在一个方向上只走一条线。
- **LACP**（802.1AX）：两端用来自查的协议。它交换 LACPDU，确认哪些链路算这个组里的、这条链路还活着。
- **active / passive**：active 一侧主动发 LACPDU，passive 一侧只回应。至少一侧得是 active，否则没人先开口。
- **admin-key**：一组成员要对上的编号。key 不一致，成员进不了同一个组。
- **min-links**：LAG 保持 up 至少需要几个可用成员。

## 机制：一帧进来，走哪根线

LAG 对外是一个接口，对内是一组成员。报文到了 LAG，交换机按源目 MAC、IP、端口这些字段算哈希，选出一个成员，再从那条线发出去。

这带来两个直接后果。聚合带宽是各成员之和，但只对多条流成立；一条流最多跑满一个成员，别指望单条 TCP 连接从 1 Gbit/s 变成 2 Gbit/s。

LACP 负责让这个组保持诚实。两端周期性互发 LACPDU，里面带着 System ID、端口号、admin-key 和成员状态。下面几条同时满足，成员才会进入转发集合：

- 两端都认为这条链路该进这个 LAG；
- admin-key 一致；
- 链路物理状态正常，LACPDU 还在收；
- 可用成员数满足 min-links。

成员掉线时，它退出转发集合，流量重新哈希到剩下的成员。min-links 还够，业务就不中断；不够，LAG 会主动 down。宁可不转发，也不拿一条残废的链路硬扛。

## 动手配一下

在 SR Linux 上，先让物理口认领 LAG，再配 LAG 本身。注意 `ethernet-1/1`、`ethernet-1/2` 只写 `aggregate-id`，地址配在 `lag1` 的子接口上。

```sh
# 在交换机上执行：把 CLI 命令喂给 sr_cli
sr_cli -d <<'EOF'
enter candidate
set / interface ethernet-1/1 ethernet aggregate-id lag1
set / interface ethernet-1/2 ethernet aggregate-id lag1
set / interface lag1 lag lag-type lacp
set / interface lag1 lag lacp lacp-mode ACTIVE
set / interface lag1 subinterface 0 ipv4 address 10.0.0.1/30
set / network-instance default interface lag1.0
commit now
EOF
```

对端把地址换成 `10.0.0.2/30`，`lacp-mode` 可以先留 `PASSIVE`。只要一侧 active，协商就能起来。

## 看什么才算配好了

配完先看聚合，再谈连通性：

```sh
sr_cli -d "show lag"                       # lag 是否 up？成员是否 up？oper-down-reason 是什么？
sr_cli -d "ping -c 2 10.0.0.2 network-instance default"
```

`show lag` 里有三处要盯：`lag1` 的状态、每个成员的 `oper-state`、没起来时的 `oper-down-reason`。本章最常见的两个原因是 `no-active-links` 和 `lacp-down`。

ping 通只说明数据面能走，聚合本身可能还没完全正常。两个都要看。

## 几个常见坑

### 两侧都是 passive，为什么起不来？

passive 只应答，不主动发。两边都等对方先开口，就永远等不到。把一侧改成 active。

### admin-key 不一致会怎样？

成员会被挡在组外，`oper-down-reason` 显示 `lacp-down`。两端改成同一个 key 才能进。

### 为什么单条流跑不满聚合带宽？

哈希按流算，一条流只落在一个成员上。想压满带宽，多开几条并发流。

### min-links 设了有什么用？

可用成员低于阈值时，LAG 主动 down，上游路由随之撤销，流量改走别的路径。这样不会从一个已经降级的组里继续漏流量。
