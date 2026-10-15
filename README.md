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
- LACP 章需要 `ghcr.io/nokia/srlinux:24.10.1`（拓扑已设 `shm-size: 1g`；24.7.1 在本环境无法提交配置）
- BGP 章需要 `quay.io/frrouting/frr:10.7.1` 与 `nicolaka/netshoot:v0.13`（抓包/解构用 tshark）
- `make debug` 现在通过 `clablings debug` 启动 `clab-tui`，需要 PATH 上同时有 `clablings` 与 `clab-tui`（`clablings` 可在 `clablings/` 下用 `go build -o /usr/local/bin/clablings ./cmd/clablings` 安装到 PATH）。

题库可通过 `CLABLINGS_ROOT` 环境变量或 `--root` 指向任意路径（便于独立成官方题库仓）。

## 交互

`clablings watch` 中按 `c` 可阅读当前章节的概念与 RFC 阅读切片；quiz 题会在 watch 中自动提示作答（多选以逗号分隔选项编号，答错显示解释并重新提示，答对后进入下一题）。

## 章节

| 章节 | 题型 | 触发方式 | 说明 |
|---|---|---|---|
| 01-vlan-trunk | quiz + 运行态 config-fix（含抓包） | Enter | 从"为什么"理解 access/trunk/native VLAN 的收发包行为，观察无标签/带标签帧（Linux bridge） |
| 02-stp | quiz + 文件驱动 config-fix | 哨兵 + Enter | 理解 STP 根桥选举与环路防护，调整优先级让核心交换机成为根 |
| 03-lacp | quiz + 文件驱动 config-fix | 哨兵 + Enter | 理解链路聚合与 LACP 协商，修复 active/passive 让 LAG 起来（SR Linux） |
| 04-mlag | quiz（概念章，无实验） | 答题推进 | 理解 MLAG/vPC、脑裂与 EVPN 多归，对比堆叠 |
| 05-bgp-basics | quiz + 运行态 config-fix（含抓包） | Enter | 理解 eBGP 会话建立与状态机，修复 remote-as、协商 hold time（FRR） |
| 06-bgp-messages | quiz + 运行态 config-fix（含抓包） | Enter | 理解 BGP 报文格式，修复未通告（ebgp-requires-policy）、解构 UPDATE/NOTIFICATION（FRR） |
| 07-bgp-attributes | quiz + 运行态 config-fix | Enter | 理解 BGP 选路与属性，用 LOCAL_PREF/AS_PATH 改变选路（FRR） |
| 08-bgp-troubleshoot | quiz + 运行态 config-fix（含抓包） | Enter | BGP 排错：卡 Active、bad peer AS、iBGP next-hop-self（FRR） |
| 09-bgp-code | code-implement（C） | 哨兵 + Enter | 用 C 实现最小 BGP speaker：OPEN/KEEPALIVE 建会话、UPDATE 通告前缀（FRR 对等） |

## M1 路线（已完成）

VLAN/Trunk ✅ → STP/RSTP ✅ → 链路聚合 LACP ✅ → MLAG/EVPN-MH（概念）✅。

> 完整 EVPN-MH 实验（underlay + iBGP EVPN + ESI + 双归主机 LAG）留作后续。

## BGP 路线（已完成）

BGP basics（会话建立/状态机）✅ → 报文格式 ✅ → 路径选择 ✅ → 排错 ✅ → C 实现最小 speaker ✅。
