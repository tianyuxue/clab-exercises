# 01_speaker

用 C 写一个最小 BGP speaker，与 `r1`（AS 65002）建立会话并通告 `192.0.2.0/24`。
程序以对端地址作为 `argv[1]`。

## 里程碑

1. **连接与 OPEN** —— TCP 连接对端 179 端口，发出合法 OPEN（`version=4`、
   `my AS=65001`、`hold time=90`、`BGP identifier=10.1.12.1`、无可选参数）。
   `r1` 的日志/`show bgp summary` 应出现该对端。
2. **Established** —— 读取对端 OPEN，发出 KEEPALIVE，读取对端 KEEPALIVE；会话进入
   Established。每 30 秒（hold/3）发一次 KEEPALIVE 以维持。
3. **UPDATE** —— 发送携带 ORIGIN、AS_PATH（65001）、NEXT_HOP `10.1.12.1` 与
   NLRI `192.0.2.0/24` 的 UPDATE。`r1` 随即学到该前缀。

## 构建与运行

`clablings` 会构建 `bgp-speaker`（见 `Makefile`）并在 `speaker` 节点运行。日志在
该节点的 `/tmp/bgp.log`：`docker exec <speaker> cat /tmp/bgp.log`

完成后记得删除 `src/main.c` 里的 `// I AM NOT DONE` 行，然后按 Enter 验证。

## 说明

上述布局在本练习中足够：FRR 会在 TCP 连接后立即发出自己的 OPEN，Established 之后
你无需再读取入向报文。更完整的实现还会校验入向报文类型、回应 NOTIFICATION，并使用
对端 OPEN 协商出的 Hold Time（取两者较小值）。
