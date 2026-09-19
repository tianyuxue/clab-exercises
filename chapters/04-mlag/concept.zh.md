# MLAG 与 EVPN 多归

## 为什么

服务器单归到一台交换机，交换机一挂服务器就断。最直接的补救——接到**两台**交换机——
同时打破两个假设：

- 服务器的 LACP bond 现在面对**两个不同的 LACP 伙伴**，无法形成单一捆绑（还可能
  抖动或黑洞）。
- 两条上行构成**二层环路**，必须阻塞，于是又浪费一半带宽。

你想要的是：冗余、active/active 带宽、且不被 STP 阻塞。

## 是什么

**MLAG**（多机箱链路聚合，Cisco vPC、MC-LAG）让两台交换机对服务器表现为**同一个**
LACP 伙伴。它们通过 **peer-link** 互连，peer-link 承载二层流量，并由控制协议保持两台
peer 对 LAG 的认知一致。**EVPN 多归（EVPN-MH）** 用开放标准达到同样效果：两台 leaf 把
接入链路绑定到共享的 **Ethernet Segment Identifier（ESI）**，再由 BGP EVPN 通告该
网段，使两台交换机协调转发。

## 怎么做

- **Peer-link**：在两台 MLAG peer 之间承载二层；若 peer-link 断而上行仍在，两台 peer
  都可能认为自己在拥有 LAG——即**脑裂**。生产 MLAG 会加 keepalive 与主/备角色来裁决。
- **Orphan 口**：只接在一台 peer 上的单归端口；它们要靠 peer-link 才能到达另一台 peer。
- **EVPN-MH**：每台 leaf 通告 **Ethernet Auto-Discovery（A-D）/ ES 路由**；通过
  **Designated Forwarder** 选举决定谁泛洪 BUM 流量，因此转发不需要 peer-link，也没有
  被阻塞的一半带宽。
- **堆叠**（StackWise/VSS）：把多台交换融合为一个控制面、单一管理与故障域——简单，但
  私有，且故障影响面更大。MLAG/EVPN-MH 保留两个独立控制面。

## 精读

读懂 EVPN 如何通告 Ethernet Segment。然后回答：什么替代了 peer-link 的角色？为什么
all-active 优于阻塞一条上行？
