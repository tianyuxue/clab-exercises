# 03_next_hop_self

先看现象：`core` 的 BGP 表里有 `192.0.2.0/24`，路由表里却没有。`ping 192.0.2.1` 不通，`ip route get` 也找不到这条前缀。

## 问题在哪

这条前缀从 `ext` 经 eBGP 进入 `edge`，下一跳是 `10.1.12.2`。`edge` 再通过 iBGP 通告给 `core` 时，默认保留这个下一跳。

`core` 只有 `10.1.1.0/30` 的直连路由，到不了 `10.1.12.2`。BGP 认为路径无效，于是不把它装进路由表。

## 抓包或观察

在 `core` 上看这条前缀：

```sh
docker exec <core> vtysh -c 'show bgp ipv4 unicast 192.0.2.0/24'
```

输出里 NEXT_HOP 是 `10.1.12.2`，路径会标成无效（inaccessible）。再看 `ip route get 192.0.2.1`，没有可用的下一跳。

## 动手修

在 `edge` 上给 iBGP 邻居打开 `next-hop-self`，让它通告时把下一跳改成自己的 `10.1.1.1`，然后重置会话：

```sh
docker exec <edge> vtysh -c 'conf t' -c 'router bgp 65001' -c 'neighbor 10.1.1.2 next-hop-self' -c 'end' -c 'clear bgp *'
```

按 Enter 验证。想重新注入故障，按 `f`。
