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
- `make debug` 现在通过 `clablings debug` 启动 `clab-tui`，需要 PATH 上同时有 `clablings` 与 `clab-tui`（`clablings` 可在 `clablings/` 下用 `go build -o /usr/local/bin/clablings ./cmd/clablings` 安装到 PATH）。
- C 题首次构建会拉取题目声明的构建镜像（默认 `gcc:13`）

题库可通过 `CLABLINGS_ROOT` 环境变量或 `--root` 指向任意路径（便于独立成官方题库仓）。

## 交互

`clablings watch` 中按 `c` 可阅读当前章节的概念与 RFC 阅读切片；quiz 题会在 watch 中自动提示作答（多选以逗号分隔选项编号，答错显示解释并重新提示，答对后进入下一题）。

## 章节

| 章节 | 题型 | 触发方式 | 说明 |
|---|---|---|---|
| 01-vlan-trunk | quiz + 文件驱动 config-fix | 哨兵 + Enter | 理解 VLAN/802.1Q，修复 Linux bridge 两端 access VLAN 不一致 |

## M1 路线（进行中）

VLAN/Trunk（本章）→ STP/RSTP → 链路聚合 LACP → MLAG/EVPN-MH（L2 交换主线）。
