# 04_tagged_host

`h4` 自己给帧打标签（VLAN 子接口）并接在 `sw2` 的 trunk 口上，却无法到达 `h1`。

## 为什么

trunk 口不要求对端是交换机。任何懂 802.1Q 的设备——带 VLAN 子接口的服务器或
虚拟化主机——都能接在 trunk 上，发出的帧本身就带标签。关键在于设备的 VLAN ID 必须是
trunk 放行的 VLAN，否则交换机丢弃。

## 观察

在 clab-tui 里对 trunk（sw1 eth3）抓包、同时 `h1` ping `h4`。帧本身就带 `vlan 10`，
由主机发出。

## 修复

把 `h4` 的子接口设为 VLAN 10：
`docker exec <h4> ip link del eth1.30; docker exec <h4> ip link add link eth1 name eth1.10 type vlan id 10`
再加地址并 up（见 `h4/h4.sh`）。

按 Enter 验证；按 `f` 重新注入故障。
