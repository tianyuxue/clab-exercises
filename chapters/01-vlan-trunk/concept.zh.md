# VLAN 与 Trunk

## 为什么

交换机会把未知单播、广播、组播帧泛洪到**同一广播域**的所有端口。扁平网络越大，
广播域越大：噪声更多、攻击面更大，而且不增加交换机就无法隔离不同团队/租户。
你需要把一张物理网络切成多个逻辑网络。

## 是什么

**VLAN** 是逻辑广播域。不同 VLAN 的端口就像在不同交换机上，即使共享同一批
物理链路。这让一台接入交换机可以服务多个互相隔离的网段。

## 怎么做

- **802.1Q 标签**：插在源 MAC 与 EtherType 之间的 4 字节字段，含 12 位 **VID**
  （0–4095）与 3 位 **PCP** 优先级。
- **Access 端口**：只属于一个 VLAN，出帧不带标签；入向无标签帧归属由 **PVID** 决定。
- **Trunk 端口**：承载多个 VLAN，帧带标签；**native VLAN** 处理 trunk 上的无标签流量
  （两端必须一致）。
- **Linux bridge VLAN filtering**：`bridge vlan add dev ethX vid N pvid untagged`
  配置 access 口；添加多个 VID 即成为 trunk。

## 精读

读懂标签结构与 access/trunk 的区别，然后回答：若两台主机同网段，但所在端口 PVID
不同，为什么 ARP 根本到不了对端？
