# 03_native

先看现象：VLAN 20 是 trunk 的 **native VLAN**。`h2` 在 sw1，`h4` 在 sw2，两边都在 VLAN 20，却互相不通。

## 问题在哪

Native VLAN 的帧在 trunk 上不打标签，这是为了兼容不会打标签的设备和链路。

可裸帧自己不带 VLAN 信息，到了对端只能按接收口的 **PVID** 来分。两端 Native VLAN 一旦对不上，同一帧就会被分到不同 VLAN，最后被悄悄丢掉，也不会报什么错。

## 抓包看什么

在 clab-tui 里对 trunk（`sw1 eth3`）抓包，同时让 `h2` ping `h4`。

VLAN 20 的帧不带标签；要是链路上还有 VLAN 10 流量，那部分仍然会显示 `vlan 10`。

## 动手修

`sw1` 这边已经对了，只要把 `sw2` 的 trunk 也设成 native VLAN 20：

```sh
docker exec <sw2> bridge vlan add dev eth1 vid 20 pvid untagged
```

按 Enter 验证；按 `f` 重新注入故障。
