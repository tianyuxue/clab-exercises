# 01_stuck_active

先看现象：`edge` 到 `ext` 的 eBGP 邻居一直停在 Active。`show bgp summary` 里看不到 Established，前缀数也是 0。

## 问题在哪

`edge` 的 `eth2` 是 `10.1.12.1/30`，对端 `ext` 是 `10.1.12.2/30`。但配置里的邻居地址写成了 `10.1.12.9`。

这个地址不在链路网段里，`edge` 没有到它的路由，TCP 179 自然建不起来。BGP 只能退回 Active，反复重试。

## 抓包或观察

登录 `edge` 看邻居状态：

```sh
docker exec <edge> vtysh -c 'show bgp summary'
```

邻居落在 Active/Connect 列。再对一下 `eth2` 的地址和邻居地址，问题就很明显。

## 动手修

删掉错误邻居，补上正确的 `10.1.12.2`，然后重置会话：

```sh
docker exec <edge> vtysh -c 'conf t' -c 'router bgp 65001' -c 'no neighbor 10.1.12.9 remote-as 65002' -c 'neighbor 10.1.12.2 remote-as 65002' -c 'end' -c 'clear bgp *'
```

按 Enter 验证。想重新注入故障，按 `f`。
