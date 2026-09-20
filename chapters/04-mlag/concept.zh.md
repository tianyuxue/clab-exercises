# MLAG 与 EVPN 多归

## 场景

一台服务器分别接到**两台**交换机，以便在其中一台故障时仍能工作：一根线到 `sw1`，另一根到
`sw2`，两台交换机相互独立。服务器同时运行 LACP，期望这两根线组成一个捆绑。

## 术语

- **MLAG**（多机箱链路聚合；Cisco vPC；MC-LAG）：让两台独立交换机对服务器表现为**同一个**
  LACP 伙伴的技术。
- **peer-link**：两台 MLAG 交换机之间的链路，用于承载二层流量，并让它们对捆绑的认知保持
  一致。
- **orphan 端口**：接在其中一台 peer 上的单归端口（不属于 MLAG）；它只能经 peer-link 才
  能到达另一台 peer。
- **脑裂（split-brain）**：peer-link 断开、但两台 peer 都在转发、各自都以为自己在拥有该
  LAG 的故障状态。
- **EVPN**：承载二层/三层可达性（MAC/IP）与多归信息的 BGP 地址族。
- **EVPN 多归（EVPN-MH）**：厂商 MLAG 的开放标准替代——两台交换机用 BGP EVPN 协同接入
  链路，而不依赖 peer-link。
- **ESI**（Ethernet Segment Identifier）：两台交换机给同一段接入网络起的共享名字，让网络
  知道它们共同对该段做多归。
- **Designated Forwarder（DF）**：在一个 ES 的若干交换机中，被选出负责为某 VLAN 泛洪广播/
  未知单播/组播（BUM）流量的那台。
- **all-active / single-active**：ES 的所有交换机是同时转发（all-active），还是同一时刻只有
  一台转发（single-active）。
- **堆叠（stacking）**：把多台交换机融合成一台设备，拥有单一控制面与单一管理/故障域。

## 为什么疼

把服务器双归到两台独立交换机，同时打破了服务器所依赖的两件事：

1. 它的 **LACP** 现在面对两个不同的伙伴（两个 System ID），无法跨两根线形成一个捆绑。
2. 两根上行在交换机之间构成**二层环路**，STP 通过阻塞其中一条来消除环路——于是两根线里有
   一根完全不承载流量。

## 为什么直觉方案不行

- **让 STP 阻塞一条上行**：服务器实际又变成单归；被阻塞的线白费，且故障切换需要数秒。
- **把两台交换机堆叠**：确实让它们成为一个 LACP 伙伴，但也把它们合并成单一控制面、单一
  故障域——一次糟糕的软件升级或主控故障会拖垮整个堆叠。

## 机制

MLAG 与 EVPN-MH 都保留**两个独立的控制面**，同时让它们在服务器眼里像一个伙伴：

- **MLAG**：**peer-link** 在两台 peer 之间承载二层流量，控制协议让两者对捆绑的认知保持
  一致。服务器的 LACP 只看到一个 System ID，从而跨两根线形成一个捆绑。当 peer-link 断而
  两条上行仍在时很危险——两台 peer 都可能认为自己在拥有该 LAG（**脑裂**）——因此生产
  MLAG 会加 keepalive 与主/备角色来裁决。
- **EVPN-MH**：两台交换机把接入链路绑定到共享的 **ESI**，并用 **BGP EVPN** 通告。通过
  **Designated Forwarder** 选举决定谁泛洪 BUM 流量，于是接入链路可以同时转发
  （**all-active**），既不需要 peer-link，也没有被阻塞的一半带宽。这是取代厂商 MLAG 的
  现代开放标准做法。

## 配置与查看

本章没有实验；需要记住的查看命令：

- 在 Linux/SR Linux 交换机上，`show lag` 查看捆绑及其成员；
- 在 EVPN-MH 交换机上，Ethernet Segment 及其 ESI 可在 EVPN 状态中看到（SR Linux：
  `network-instance … protocols bgp-evpn ethernet-segments` 之下）。

## 常见问题

- **peer-link 故障 = 脑裂**：没有 keepalive 与主/备角色时，两台 peer 可能都接受 LAG，导致
  流量黑洞。
- **orphan 端口**：接在某台 peer 上的单归端口依赖 peer-link 才能到达另一台 peer；peer-link
  中断会把它隔离。
- **堆叠并非免费**：它放弃了"两个控制面"的好处——单一故障域、更大的影响面。
- **EVPN-MH 需要控制面**：必须在两台交换机上配置 ESI/BGP EVPN；否则它们仍是两个互不相关
  的 LACP 伙伴。
