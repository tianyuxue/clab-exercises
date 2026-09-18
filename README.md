# Clablings 题库

在 `clablings/` 目录下运行（题库位于仓库根 `clab-exercises/`）：

```bash
go run ./cmd/clablings watch --root ../clab-exercises
go run ./cmd/clablings run <id> --root ../clab-exercises
go run ./cmd/clablings reset [<id>] [--hard] --root ../clab-exercises
go run ./cmd/clablings list --root ../clab-exercises
go run ./cmd/clablings test --all --root ../clab-exercises
```

## 前置

- Linux 主机，已安装 containerlab、Docker
- `make debug` 需要 PATH 上有 `clab-tui`
- C 题首次构建会拉取题目声明的构建镜像（默认 `gcc:13`）

## 章节

| 章节 | 题型 | 触发方式 | 说明 |
|---|---|---|---|
| 01-ospf-mtu | 运行态 config-fix | Enter | 修复 OSPF MTU 不匹配导致的邻居卡 ExStart |
| 02-arp-responder | code-implement | 哨兵 + Enter | 用 C 实现替虚拟 IP 应答 ARP |
| 03-route-fix | 文件驱动 config-fix | 哨兵 + Enter | 修复 routes.sh 中错误的静态路由下一跳 |
