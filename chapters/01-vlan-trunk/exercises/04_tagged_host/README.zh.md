# 04_tagged_host

先看现象：`h4` 用 VLAN 子接口自己给帧打标签，接在 `sw2` 的 trunk 口上，可就是到不了 `h1`。

## 问题在哪

Trunk 口对面不一定非得是交换机。服务器、虚拟化主机，只要会 802.1Q，都能自己打标签接上来。

关键是它用的 VLAN ID 得在 trunk 的放行列表里；不在的话，交换机收到就丢。

## 抓包看什么

在 clab-tui 里对 trunk（`sw1 eth3`）抓包，同时让 `h1` ping `h4`。

修好以后，`h4` 发出的帧会带 `vlan 10`；故障状态下 `h4` 用的是 VLAN 30，帧根本到不了 trunk。

## 动手修

把 `h4` 的子接口改到 VLAN 10：

```sh
docker exec <h4> ip link del eth1.30
docker exec <h4> ip link add link eth1 name eth1.10 type vlan id 10
docker exec <h4> ip addr add 10.0.10.4/24 dev eth1.10
docker exec <h4> ip link set eth1.10 up
```

按 Enter 验证；按 `f` 重新注入故障。
