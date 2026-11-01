# 02_hold_time

先看现象：r1 和 r2 的会话已经 Established，计时器用的是默认值。r1 发出的 OPEN 里，Hold Time 是 180 秒。

## 问题在哪

Hold Time 和 KEEPALIVE 间隔都在 OPEN 里协商，默认是 180 秒和 60 秒。要让对端在 9 秒内发现 r1 失联，就得让 r1 提议 Hold Time 9 秒、KEEPALIVE 3 秒。

计时器只在建会话时谈。配置改了，旧会话还按老值跑，必须重置。

## 抓包看什么

sniff 上一直在抓 `/tmp/bgp.pcap`。直接看 r1 发出的 OPEN：

```sh
docker exec <sniff> tshark -r /tmp/bgp.pcap -Y 'bgp.type==1 && ip.src==10.1.12.1' -T fields -e bgp.open.holdtime
```

修好之前，最后一行是 180；重置会话后，新抓到的 OPEN 应该是 9。

## 动手修

在 r1 上配邻居计时器，FRR 的顺序是先 KEEPALIVE 后 Hold Time：

```sh
docker exec <r1> vtysh -c 'conf t' -c 'router bgp 65001' -c 'neighbor 10.1.12.2 timers 3 9'
```

然后重置会话：

```sh
docker exec <r1> vtysh -c 'clear bgp *'
```

按 Enter 验证；按 `f` 重新注入故障。
