# 02_aspath

先看现象：`r1` 通告 `192.0.2.0/24` 时，线上抓到的 AS_PATH 只有一个 `65001`。目标是让对端看到 `65001,65001,65001`，也就是在出向 UPDATE 上再 prepend 两次。

## 问题在哪

AS_PATH 是路径属性，每经过一个 AS 就追加一次它的 AS 号。r1 发布这条前缀，正常会写一次 `65001`；要让路径看起来更长，就在出向策略里手动再加两次。

注意改的是发出去的那一份。本地路由表里的 AS_PATH 不会因此变化。

## 抓包或观察

sniff 桥接在 r1 和 r2 之间，179 端口的报文都会经过它。先看当前 UPDATE 里的 AS_PATH：

```sh
docker exec <sniff> tshark -r /tmp/bgp.pcap -Y 'bgp.type==2 && ip.src==10.1.12.1' -T fields -e bgp.update.path_attribute.as_path_segment.as4 | tail -1
```

改之前，最后一行只有一个 `65001`。

## 动手修

在 r1 上建 route-map，挂到邻居的出向，然后重置会话：

```sh
docker exec <r1> vtysh -c 'conf t' -c 'route-map PREPEND permit 10' -c 'set as-path prepend 65001 65001' -c 'router bgp 65001' -c 'neighbor 10.1.12.2 route-map PREPEND out'
docker exec <r1> vtysh -c 'clear bgp *'
```

新属性要等下一次 UPDATE 才带出去，所以 `clear bgp *` 这一步不能省。重置后再跑一次上面的 tshark，AS_PATH 应该变成 `65001,65001,65001`。

按 Enter 验证；按 `f` 重新注入故障。
