# 02_trunk

先看现象：`h1` 接在 `sw1`，`h3` 接在 `sw2`，两边都是 VLAN 10，可跨 trunk 就是不通。

## 问题在哪

两台交换机之间只有一条线，却要同时跑好几个 VLAN。帧上要是没标签，对端根本分不清它是 VLAN 10 还是 VLAN 20，二层隔离就没了。

所以 trunk 上的帧得带 802.1Q 标签；而且交换机只转发 trunk 放行的 VLAN。

## 抓包看什么

在 clab-tui 里对 `sw1` 的 trunk 口 `eth3` 抓包，同时让 `h1` ping `h3`。

修好以后，VLAN 10 的帧上能看到 `vlan 10`；access 口 `eth1` / `eth2` 那边还是不带标签。

## 动手修

两台交换机的 trunk 都要放行 VLAN 10：

```sh
docker exec <sw1> bridge vlan add dev eth3 vid 10
docker exec <sw2> bridge vlan add dev eth1 vid 10
```

按 Enter 验证；按 `f` 重新注入故障。
