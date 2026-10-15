# VLAN 与 Trunk

## 场景

一间小办公室用一台交换机：二十四台机器在同一网段、同属一组。后来一个"吵闹的"
测试实验台接到同一台交换机上，它的广播到达每台机器，整个网络变慢。

## 术语

- **广播域（Broadcast domain）**：一个广播能到达的端口集合；交换机把广播——以及目的 MAC 未学习的帧（未知单播）——泛洪到该域内除入端口外的每个端口。
- **VLAN**：逻辑上的广播域；不同 VLAN 的两个端口永远看不到彼此的广播。
- **802.1Q 标签（802.1Q tag）**：插在源 MAC 与 EtherType 之间的 4 字节字段，携带 12 位 VLAN ID。
- **PVID**：端口给"没有标签的入向帧"指定的 VLAN。
- **Access 口**：把单个 VLAN 放到一条线上、不带标签的端口。
- **Trunk 口**：在设备之间承载多个 VLAN、带标签的端口。
- **Native VLAN**：trunk 上唯一一个帧不带标签传输的 VLAN。

## 痛点

扁平网络就是一个广播域，因此每个广播与未知单播帧都泛洪到所有设备，吵闹的实验台也在内。
交换机没有旋钮能在共享硬件的同时把两组分开。

## 为什么直觉方案不行

买第二台交换机再连起来，只是把同一个广播域扩大，问题照旧；为冗余再加一条链路只会
形成二层环路。

## 机制

交换机只会看到字节，因此它必须判断每一帧属于哪个广播域。三条规则都取决于"这个判断
只能发生在哪里"。

**为什么 access 口无标签、用 PVID。** 普通主机网卡默认不懂 802.1Q：既不打标签也不剥标签，
收到带标签的帧会当成未知 EtherType 丢弃。所以在主机链路上交换机保持帧无标签。但交换机仍要
把裸帧放进某个 VLAN——这就是端口的 PVID。这条链路只承载一个 VLAN，标签本身也不带信息。

**为什么 trunk 打标签。** 两台交换机之间的一条线要承载多个 VLAN。若帧不带标签，对端分不清
VLAN10 与 VLAN20，隔离就崩溃。所以 trunk 给每帧带上 802.1Q 的 VLAN ID（native VLAN 的帧
除外，下一段说明）：在共享链路上，标签是这帧唯一的身份。

**为什么需要 native VLAN。** 有些设备和链路不打标签。为让它们也能用 trunk，约定一个
VLAN 为 native：其帧不带标签传输，仿佛这条 trunk 是该 VLAN 的 access 口。代价是裸帧
自身没有身份——唯一决定它归属的是**接收端 PVID**。两端不一致时，同一帧落在不同 VLAN，
而且是静默失败。

## 配置与查看

```sh
ip link add br0 type bridge vlan_filtering 1 && ip link set br0 up
ip link set eth1 master br0 && ip link set eth2 master br0 && ip link set eth3 master br0

bridge vlan add dev eth1 vid 10 pvid untagged      # access：单 VLAN，无标签
bridge vlan add dev eth3 vid 10                    # trunk：VLAN 10 带标签
bridge vlan add dev eth3 vid 20 pvid untagged      # trunk 的 native VLAN 20

bridge vlan show                                    # 每端口的 PVID 与出向标签
```

在链路上，access 看不到标签，trunk 上带标签的 VLAN10 流量显示 `vlan 10`（native VLAN
仍是无标签穿越）：
```sh
tcpdump -i eth1 -e -nn     # access：没有 "vlan"
tcpdump -i eth3 -e -nn     # trunk：带标签的 VLAN10 帧显示 "vlan 10"
```

## 常见问题

- 同网段却不通？两个 access 口的 PVID 不一致；主机裸帧落进不同 VLAN，即使同网段也如此。
- 跨交换机同 VLAN 却不通？trunk 不是该 VLAN 的成员，帧被丢弃。
- native VLAN 不一致？裸帧由接收端 PVID 归属；不一致会把它放进另一个 VLAN，且静默。
- 主机能接在 trunk 上吗？能——只要它用 VLAN 子接口自己打标签，且用的是 trunk 放行的 VLAN。
