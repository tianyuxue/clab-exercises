# 01_access

先看现象：`h1` 和 `h2` 都接在 `sw1` 上，IP 也在同一个网段，可就是互相 ping 不通。

## 问题在哪

电脑网卡不认识 802.1Q，发出去的帧都不带标签。交换机收到这种裸帧，只能看它从哪个口进来，再按这个口的 **PVID** 给它分 VLAN。

两个 access 口的 PVID 要是不一样，h1 和 h2 就被分到两个 VLAN 里了。IP 同网段也没用，ARP 都过不去。

## 抓包看什么

在 clab-tui 里对 `sw1` 的 `eth1` 抓包（就是朝向 `h1` 的那个口）。你会看到帧上没有任何 VLAN 标签。交换机在主机这边保持无标签，VLAN 是它内部按 PVID 分的。

## 动手修

先看两个口的 PVID：

```sh
docker exec <sw1> bridge vlan show
```

然后把 `eth2` 从 VLAN 20 挪到 VLAN 10：

```sh
docker exec <sw1> bridge vlan del dev eth2 vid 20
docker exec <sw1> bridge vlan add dev eth2 vid 10 pvid untagged
```

改完按 Enter 验证。想从头再来就按 `f`。
