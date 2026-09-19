# VLAN 与 Trunk

## 场景

一个小办公室有一台交换机，24 台电脑接在上面，都在同一个网段 `10.0.1.0/24`。某台电脑
发出一个 ARP 请求时，其他电脑都会收到——交换机就是这样工作的，这个规模下也没问题。

后来办公室里在同一台交换机上接了一间"话很多"的测试机房。它的广播流量也会到达办公电脑，
整个网络开始变慢。

## 术语

- **广播域（broadcast domain）**：一个广播帧能到达的端口集合。交换机会把广播帧（以及
  目的 MAC 尚未学习到的帧）泛洪到同一广播域的所有端口。
- **扁平网络（flat network）**：所有设备共用一个广播域的网络。当我们说"网络变大了"，
  其实总是指"广播域变大了"。
- **VLAN**：*逻辑*广播域。不同 VLAN 的两个端口即使在同一台物理交换机上，也永远看不到
  彼此的广播。
- **802.1Q 标签（tag）**：交换机插在源 MAC 与 EtherType 之间的 4 字节字段，含 12 位
  **VLAN ID**（VID，1–4094）与 3 位**优先级**（PCP）。
- **Access 端口**：只属于一个 VLAN、出帧不带标签的端口。它的 **PVID**（端口 VLAN ID）
  决定入向无标签帧属于哪个 VLAN。
- **Trunk 端口**：承载多个 VLAN、出帧带标签的端口。它的 **native VLAN** 处理 trunk 上的
  无标签帧；两端必须一致。

## 为什么疼

按定义，扁平网络只有一个广播域，所以每个广播、每个未知单播都会被泛洪到所有设备——包括
那间吵闹的机房。交换机上没有任何旋钮能在"共用同一批硬件"的前提下把两组隔开。

## 朴素修法为何不行

最直接的想法是再买一台交换机，把机房挪过去。若两台交换机相连，这条链路仍然属于*同一个*
广播域，问题原样回来了。若为了冗余再加一条互联链路，反而更糟：两条链路构成二层环路，
STP 会阻塞其中一条——你为一条用不上的链路付了钱。

## 机制

**VLAN** 把一台物理交换机切成多个互相独立的广播域。你不再靠买硬件来隔离，而是把端口
划分到 VLAN：

- **access 端口**在单根线缆上承载单个 VLAN，不带标签；
- **trunk 端口**在交换机之间承载多个 VLAN，用 **802.1Q 标签**标记，使对端知道每个帧
  属于哪个 VLAN。

因为标识 VLAN 的是标签（而不是线缆），一根线缆可以承载多个逻辑网络，环路/阻塞的问题也
随之消失——你是在逻辑上、而非物理上隔离各组。

## 配置与观察

在 Linux 网桥上，必须先对网桥开启 VLAN filtering，端口的 VLAN 设置才生效：

```sh
ip link add br0 type bridge vlan_filtering 1 && ip link set br0 up
ip link set eth1 master br0 && ip link set eth2 master br0

# access 端口：单个 VLAN，不带标签
bridge vlan add dev eth1 vid 10 pvid untagged
bridge vlan add dev eth2 vid 10 pvid untagged

# trunk 端口：多个 VLAN，带标签
bridge vlan add dev eth3 vid 10
bridge vlan add dev eth3 vid 20

bridge vlan show          # 查看每个端口的 PVID 与出向标签
```

## 常见坑

- **同网段、不同 PVID**：两台主机可能在同一 IP 网段，但所在 access 端口 PVID 不同；
  它们的 ARP 被 VLAN 隔离，因此互相不通。这正是本题注入的故障。
- **native VLAN 不一致**：trunk 两端的 native VLAN 不同时，无标签帧会落到不同 VLAN，
  表现为静默不通。
- **PVID 是端口级的**：改它会影响该端口*所有*无标签流量，而不是某一台主机。
