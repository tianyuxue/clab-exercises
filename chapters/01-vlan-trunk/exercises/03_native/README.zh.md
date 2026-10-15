# 03_native

VLAN20 是 trunk 的 **native VLAN**。`h2`(sw1) 与 `h4`(sw2) 同属 VLAN20，却互不相通。

## 为什么

trunk 指定一个 VLAN，其帧**不带标签**传输，以便不打标签的设备/链路也能工作。但
无标签帧没有 VLAN 身份：唯一决定它归属的是**接收端 PVID**。两端不一致时，同一裸帧被
放进不同 VLAN——而且是**静默失败**，不报错。

## 观察

在 clab-tui 里对 trunk（sw1 eth3）抓包、同时 `h2` ping `h4`。VLAN20 的帧**无标签**，
而 VLAN10 的帧仍带 `vlan 10`。

## 修复

在两端把 VLAN20 设为 native：
`docker exec <sw2> bridge vlan add dev eth1 vid 20 pvid untagged`

按 Enter 验证；按 `f` 重新注入故障。
