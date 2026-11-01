# 02_aspath

先看现象：`r1` 还是从 `r2`、`r3` 学 `10.2.2.0/24`。这次两条路都通，`r1` 走的是 `r2`。你想让它改走 `r3`。

## 问题在哪

基线里 `r2` 的 router-id 更小，前面几项打平后，它靠平局项赢了。想在不碰 router-id 的前提下改结果，就得在更靠前的比较项上动手。

AS_PATH 排在第四位，越短越优先。`r3` 送来的路径只有一个 AS 号 `65003`。只要让 `r2` 发往 `r1` 的 UPDATE 里多带几个 `65002`，这条路径就会变长，`r1` 自然会转向 `r3`。

## 抓包或观察

先确认当前选择：

```sh
docker exec <r1> ip route get 10.2.2.100
```

下一跳是 `10.1.12.2`，也就是 `r2`。再看两条路径的 AS_PATH：

```sh
docker exec <r1> vtysh -c 'show bgp ipv4 unicast'
```

修好之前，经 `r2` 的那条显示 `65002`，经 `r3` 的显示 `65003`，长度一样，所以还是 router-id 说了算。

## 动手修

在 `r2` 上建一条出向 route-map，把本 AS 号再加两遍：

```sh
docker exec <r2> vtysh -c 'conf t' -c 'route-map PAD_65002 permit 10' -c 'set as-path prepend 65002 65002' -c 'router bgp 65002' -c 'neighbor 10.1.12.1 route-map PAD_65002 out'
```

属性要随下一次 UPDATE 才发出去，所以重置会话：

```sh
docker exec <r2> vtysh -c 'clear bgp *'
```

再看 `r1` 的路由表，下一跳应该变成 `10.1.13.2`。

按 Enter 验证；按 `f` 重新注入故障。
