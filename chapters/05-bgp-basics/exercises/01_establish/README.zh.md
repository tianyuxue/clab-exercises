# 01_establish

先看现象：`r1` 在 AS 65001（10.1.12.1/30），`r2` 在 AS 65002（10.1.12.2/30），中间一根线直连。地址和邻居都配好了，`show bgp summary` 里却始终等不到 Established。

## 问题在哪

`r2` 给邻居 `10.1.12.1` 配的 `remote-as` 是 65099。r1 发来的 OPEN 里 My AS 写着 65001，r2 一比对，直接回 NOTIFICATION “Bad Peer AS”，然后把 TCP 关掉。r1 只能重连，再被拒，来回循环。

## 抓包看什么

在 sniff 上抓 179 端口，看 r2 回的那条 NOTIFICATION：

```sh
docker exec <sniff> tshark -i any -f 'tcp port 179' -Y 'bgp.type==3' -T fields -e bgp.notification.error_code -e bgp.notification.error_subcode
```

修好之前，输出里能看到错误码 2、子码 2，也就是 Bad Peer AS。也可以在两台路由器上各看一次邻居表：

```sh
docker exec -it <r1> vtysh -c 'show bgp summary'
docker exec -it <r2> vtysh -c 'show bgp summary'
```

## 动手修

把 `r2` 上这个邻居的 `remote-as` 改成 r1 的 AS：

```sh
docker exec <r2> vtysh -c 'conf t' -c 'router bgp 65002' -c 'neighbor 10.1.12.1 remote-as 65001'
```

改完立刻生效，不用重启。按 Enter 验证；按 `f` 会重新注入故障。
