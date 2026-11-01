# 01_localpref

先看现象：`r1` 从 `r2` 和 `r3` 都学到 `10.2.2.0/24`。两条路都通，可 `r1` 现在走 `r3`。你想让它改走 `r2`。

## 问题在哪

两条路径的 AS_PATH 都只有一个 AS 号，ORIGIN 都是 IGP，MED 都是 0，eBGP 对 eBGP，IGP 度量也一样。前面几项全平，最后按 router-id 分胜负。`r3` 的 router-id 更小，所以它赢了。

LOCAL_PREF 排在 AS_PATH 前面。只要给从 `r2` 学来的路由设一个更高的 LOCAL_PREF，`r1` 就会在更早的一步改选 `r2`。

## 抓包或观察

在 `r1` 上看它现在的选择：

```sh
docker exec <r1> ip route get 10.2.2.100
```

输出里的下一跳是 `10.1.13.2`，也就是 `r3`。再看 BGP 表：

```sh
docker exec <r1> vtysh -c 'show bgp ipv4 unicast'
```

在 `10.2.2.0/24` 这一项下面，两条路径都会列出来，标着 best 的那条走 `r3`，它的 LOCAL_PREF 是默认的 100。

## 动手修

在 `r1` 上建一条入向 route-map，给从 `10.1.12.2` 学到的路由设 LOCAL_PREF 200：

```sh
docker exec <r1> vtysh -c 'conf t' -c 'route-map FROM_R2 permit 10' -c 'set local-preference 200' -c 'router bgp 65001' -c 'neighbor 10.1.12.2 route-map FROM_R2 in'
```

LOCAL_PREF 对本机路由表立即生效，不用重置会话。再跑一次 `ip route get 10.2.2.100`，下一跳应该变成 `10.1.12.2`。

按 Enter 验证；按 `f` 重新注入故障。
