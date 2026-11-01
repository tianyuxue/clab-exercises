# 01_advertise

先看现象：`r1`（AS 65001，10.1.12.1/30）和 `r2`（AS 65002，10.1.12.2/30）的会话早就 Established，`r1` 上也写了 `network 192.0.2.0/24`。可 `r2` 的路由表里就是没有这条前缀。

## 问题在哪

先别怀疑链路。邻居能到 Established，说明 TCP 179 通了，OPEN 也谈妥了。问题出在“发”的那一侧。

FRR 对 eBGP 有一条默认规则：没有策略就不通告。`show bgp summary` 会给出两个信号，`peerState` 显示 `Policy`，`pfxSnt` 停在 0。会话是好的，只是一条 UPDATE 都没发出去。

## 观察

登录 r1，看邻居状态：

```sh
docker exec -it <r1> vtysh -c 'show bgp summary'
```

如果 `peerState` 是 `Policy`、`pfxSnt` 为 0，就对上了。

## 动手修

在 r1 上放开这条限制，再重置会话：

```sh
docker exec <r1> vtysh -c 'conf t' -c 'router bgp 65001' -c 'no bgp ebgp-requires-policy'
docker exec <r1> vtysh -c 'clear bgp *'
```

改了配置还不够，UPDATE 不会自己重发。`clear bgp *` 让会话重建，r1 才会重新算一遍前缀，把它装进 UPDATE 发给 r2。

想确认结果，在 r2 上看本地 BGP 表：

```sh
docker exec <r2> vtysh -c 'show bgp ipv4 unicast'
```

应该能看到 192.0.2.0/24。

按 Enter 验证；想从头再来就按 `f`。
