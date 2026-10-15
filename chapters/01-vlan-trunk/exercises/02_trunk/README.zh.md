# 02_trunk

`h1`（在 sw1）与 `h3`（在 sw2）同属 VLAN10，却互不相通。

## 为什么

两台交换机之间的一条线要承载多个 VLAN。若帧不带标签，对端分不清 VLAN10 与
VLAN20——隔离就崩溃了。因此 **trunk** 给每帧带上 802.1Q 的 VLAN ID，并且交换机只把
trunk 所属的 VLAN 转发过这条链路。

## 观察

在 clab-tui 里对 `sw1` 的 trunk 口（eth3）抓包、同时 ping `h3`，会看到帧带 `vlan 10`。
与 access 口（eth1/eth2）对比：没有标签。

## 修复

- 在两台交换机的 trunk 上放行 VLAN 10：
  `docker exec <sw1> bridge vlan add dev eth3 vid 10`
  `docker exec <sw2> bridge vlan add dev eth1 vid 10`

按 Enter 验证；按 `f` 重新注入故障。
