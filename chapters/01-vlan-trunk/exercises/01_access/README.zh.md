# 01_access

`h1` 与 `h2` 在 `sw1` 上同网段，却互不相通。

## 为什么

主机网卡不懂 802.1Q，发出的是无标签帧。交换机必须判断这些裸帧属于哪个广播域——
它用端口的 **PVID**。两个 access 口不一致时，两台主机落在不同 VLAN，即使同网段也
看不到彼此的 ARP。

## 观察

在 clab-tui 里对 `sw1` 面向 `h1` 的口（eth1）抓包，会看到**没有 VLAN 标签**——
交换机让主机链路保持无标签。

## 修复

- `docker exec <sw1> bridge vlan show` —— 对比 eth1 与 eth2 的 PVID。
- 把 eth2 从 VLAN20 改到 VLAN10：
  `docker exec <sw1> bridge vlan del dev eth2 vid 20`
  `docker exec <sw1> bridge vlan add dev eth2 vid 10 pvid untagged`

按 Enter 验证；按 `f` 重新注入故障。
