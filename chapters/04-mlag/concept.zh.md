# MLAG 与 EVPN 多归：两台交换机怎么装成一台？

## 先看现象

一台核心服务器，两张网卡，一根接 `sw1`，一根接 `sw2`。两台交换机彼此独立，谁也不知道对方的存在。这么接线图的就是冗余：坏掉一台，另一台顶上。这种一台主机接两台交换机的接法，通常叫双归（dual-homing）。

服务器上起了 LACP bond。LACP 是链路聚合控制协议（Link Aggregation Control Protocol），两端先握手，再把多条物理链路并成一条逻辑链路，带宽叠加，还能互为备份。

结果 bond 没起来。有时勉强起来，也只有一根线在转发，另一根闲着。

## 问题在哪

LACP 握手时，每一端都要报出自己的 System ID，你可以把它理解成设备身份。服务器只有一块 bond，它期待对面只有一个身份。现在 `sw1` 一个、`sw2` 一个，服务器看到两个不同的伙伴，凑不出同一个捆绑。

那不跑 LACP，两根线都当普通口用呢？又冒出另一个问题。两台交换机之间没有任何阻断，两根上行加一台服务器，正好围成一个二层环路。STP（Spanning Tree Protocol，生成树协议）会算出一棵生成树，把其中一条上行阻塞。你花了两根线的钱，实际只有一根在跑。

## 几个绕不开的术语

- **MLAG**（Multi-Chassis Link Aggregation，多机箱链路聚合）：让两台独立交换机在服务器眼里表现为同一个 LACP 伙伴。服务器那侧的捆绑叫 LAG（Link Aggregation Group，链路聚合组）。Cisco 叫 vPC，其他厂商常写 MC-LAG。这两台交换机通常就叫 peer。
- **peer-link**：两台 MLAG 交换机之间的直连链路。它要转发两台交换机之间的二层流量，也要让两边对捆绑的认知保持一致。
- **orphan 端口**：只接在其中一台 peer 上的单归端口。它不在 MLAG 里，想去另一台 peer，只能借道 peer-link。
- **脑裂（split-brain）**：peer-link 断了，两台 peer 却都还在转发，各自都以为 LAG 归自己管。
- **EVPN**：BGP 的一个地址族，可以携带二层、三层的可达信息（MAC/IP），也能携带多归信息。
- **EVPN 多归（EVPN-MH）**：厂商 MLAG 的开放标准替代。两台交换机用 BGP EVPN 协商接入链路，不需要 peer-link。
- **ESI**（Ethernet Segment Identifier）：两台交换机给同一段接入网络起的共享名字，这一段就叫 ES（Ethernet Segment）。网络看到同一个 ESI，就知道这两台交换机在共同多归这一段。
- **Designated Forwarder（DF）**：同一个 ES 有多台交换机时，每个 VLAN 选出一台，专门负责泛洪广播、未知单播和组播（BUM）流量。
- **all-active / single-active**：ES 里的交换机是全部同时转发（all-active），还是同一时刻只留一台（single-active）。
- **堆叠（stacking）**：把几台交换机融合成一台设备，控制面（control plane）只有一个，管理域和故障域也只有一个。

## 为什么不干脆堆叠？

堆叠确实能让两台交换机变成一个 LACP 伙伴，这一点没错。但代价是它们从此只有一个控制面，也只有一个故障域。一次糟糕的软件升级，或者主控板坏掉，两台一起下线。双归本来是为了扛单台故障，堆叠把这个好处又还了回去。

让 STP 阻塞一条上行也一样。服务器实际又变回单归，被阻塞的那根线白放着，真出故障还要等几秒切换。

## MLAG 怎么做

MLAG 的思路是：两台交换机还是各自独立，只在服务器面前表现得像一个伙伴。

peer-link 负责在两台 peer 之间转发二层流量，控制协议让两边对捆绑的认知保持同步。服务器的 LACP 只看到一个 System ID，于是两根线能进同一个捆绑。

麻烦出在 peer-link 断掉、两条上行却都还活着的时候。两台 peer 都可能以为 LAG 归自己管，这就是脑裂。生产环境的 MLAG 会加一条 keepalive，再配主备角色来裁决。

还有一个容易忽略的依赖：orphan 端口。它只接在一台 peer 上，要访问另一台 peer 下的网络，必须经过 peer-link。peer-link 一断，它就被隔离了。

## EVPN 多归：连 peer-link 都不要

两台交换机给同一段接入链路配同一个 ESI，再用 BGP EVPN 把这个 ESI 通告出去。对端网络由此知道：这两台交换机在共同多归这一段。

BUM 流量不能两边都泛洪，否则接收端会收到重复帧。于是每个 VLAN 选一个 DF，由它负责泛洪，其他交换机只管已知单播。

接入链路因此可以全部同时转发，也就是 all-active。既没有 peer-link，也没有被 STP 阻塞的一半带宽。这也是现在替代厂商 MLAG 的开放标准做法。

## 配置与查看

本章没有实验，先把查看命令记住：

- Linux 或 SR Linux 交换机上，`show lag` 能看到捆绑和成员端口。
- EVPN-MH 交换机上，Ethernet Segment 和 ESI 在 EVPN 状态里。SR Linux 的路径在 `network-instance … protocols bgp-evpn ethernet-segments` 下面。

## 几个常见坑

### peer-link 断了，为什么反而更危险？

没有 keepalive，也没有主备角色时，两台 peer 都可能继续接受 LAG。流量进来，却找不到去对端的路，直接被丢进黑洞。生产环境给 MLAG 配 keepalive 和主备裁决，就是为了躲开这种脑裂。

### 单归端口为什么跟着 peer-link 一起挂？

orphan 端口只接在一台 peer 上。它要访问另一台 peer 下的网络，必须经过 peer-link。peer-link 一断，这个端口就被隔离了。

### 堆叠不是免费的

堆叠把两个控制面合成一个，管理是简单了，故障域也合并了。爆炸半径变大，升级窗口更难安排。

### EVPN-MH 配了 ESI 就够了吗？

不够。两台交换机都要配 ESI，也都要跑 BGP EVPN。少一边，它们在服务器眼里仍然是两个互不相关的 LACP 伙伴。
