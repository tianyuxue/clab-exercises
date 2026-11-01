# 01_speaker

先看现象：`r1` 上已经配好一个 AS 65001 的邻居 `10.1.12.1`，可 `show bgp summary` 里那一行一直在 `Active` 和 `Connect` 之间打转。你这边一个字节都没发出去。

## 问题在哪

TCP 连上只是把管子接通。BGP 要在管子里按顺序交换报文，状态才会往前走：

1. **连接与 OPEN**：连 `r1` 的 179 端口，发一条合法 OPEN：`version=4`、`my AS=65001`、`hold time=90`、`BGP identifier=10.1.12.1`、可选参数长度 0。`r1` 的 `show bgp summary` 里应该出现这个邻居。
2. **Established**：读掉对端 OPEN，发 KEEPALIVE，再收对端 KEEPALIVE。会话进入 Established；之后每 30 秒（hold/3）补一条 KEEPALIVE，别让 90 秒的 Hold Time 过期。
3. **UPDATE**：发一条带 ORIGIN、AS_PATH（65001）、NEXT_HOP `10.1.12.1` 和 NLRI `192.0.2.0/24` 的 UPDATE。`r1` 随即学到这个前缀。

程序入口在 `src/main.c`，对端地址从 `argv[1]` 进来。`tcp_connect`、`send_all`、`recv_message`、`put16`、`put32` 都写好了，缺的是三个 `build_*` 函数和 `main` 里的时序。

## 抓包或观察

在 `r1` 上看邻居和路由：

```sh
docker exec <r1> vtysh -c 'show bgp summary'
docker exec <r1> vtysh -c 'show bgp ipv4 unicast'
```

状态应该是 `Established`，路由表里有一条 `192.0.2.0/24`，总数 1。

程序自己的日志在 speaker 节点：

```sh
docker exec <speaker> cat /tmp/bgp.log
```

想核对字节，就在 speaker 上抓 179 端口，`-X` 会把报文按十六进制打出来。OPEN 是 29 字节，开头 16 个 `ff`；KEEPALIVE 只有 19 字节。

```sh
docker exec <speaker> tcpdump -i eth1 -nn -X port 179
```

## 动手修

把 `src/main.c` 里三个 `build_*` 函数按字节布局填好，再把 `main` 的流程接上：连、发 OPEN、读 OPEN、发 KEEPALIVE、读 KEEPALIVE、发 UPDATE、每 30 秒补 KEEPALIVE。

想在本地先看编译错误，就在练习目录里 `make`；clablings 会用 `gcc:13` 镜像重新构建，再在 speaker 节点把它跑起来。

```sh
make
```

改完删掉第一行的 `// I AM NOT DONE`，回到 clablings 按 Enter 重新构建验证。断言依次看四件事：占位行没了、邻居 Established、`r1` 学到一条路由、`r1` 能 ping 通 `192.0.2.1`。

这套时序在本练习够用：FRR 在 TCP 建链后立刻发自己的 OPEN，Established 之后你不需要再读入向报文。更完整的版本还会校验报文类型、出错时回 NOTIFICATION、用对端 OPEN 里的 Hold Time 算发送间隔（取两者较小值）。
