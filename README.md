# Clablings 题库

[![License: CC BY-SA 4.0](https://img.shields.io/badge/License-CC%20BY--SA%204.0-lightgrey.svg)](LICENSE)
[![clablings](https://img.shields.io/badge/runner-clablings-6f42c1)](https://github.com/tianyuxue/clablings)

配套 [clablings](https://github.com/tianyuxue/clablings) 使用的中文优先网络实验题库：真实 containerlab 拓扑、概念阅读、quiz、运行态排错和 C 语言实现题。

## 先装 clablings

```bash
curl -fsSL https://raw.githubusercontent.com/tianyuxue/clablings/main/scripts/install.sh | sh
```

也可以从 [clablings Releases](https://github.com/tianyuxue/clablings/releases/latest) 手动下载，或者从源码构建。

## 跑起来

```bash
git clone https://github.com/tianyuxue/clab-exercises
cd clab-exercises

clablings list
clablings watch
clablings run 01-vlan-trunk/01_access
```

`clablings` 会从当前目录往上找 `clablings.yaml`；也可以在任意位置用 `--root` 或 `CLABLINGS_ROOT` 指向题库。

```bash
clablings watch --root /path/to/clab-exercises
export CLABLINGS_ROOT=/path/to/clab-exercises
```

## 跑之前

- Linux 主机，装好 containerlab 和 Docker。
- LACP 章要用 `ghcr.io/nokia/srlinux:24.10.1`。拓扑里已经设了 `shm-size: 1g`；24.7.1 在这个环境里提交不了配置。
- BGP 章要用 `quay.io/frrouting/frr:10.7.1` 和 `nicolaka/netshoot:v0.13`，抓包和解包靠 tshark。
- 章节目录里的 `make debug` 会调用 `clablings debug` 启动 `clab-tui`，所以 PATH 上得同时有 `clablings` 和 `clab-tui`。
- 跑实验通常需要 root，或者给 containerlab 配 SUID。用户目录安装的 clablings 可以直接用 `clablings watch --sudo` 提权，不必用 `sudo clablings`（sudo 的 PATH 不含 `~/.local/bin`）。

## 怎么用

`clablings watch` 会一章一章往下走。每道题先看 brief，需要时按 `h` 看提示、按 `c` 看概念和 RFC 阅读切片，改完按 `Enter` 验证。

quiz 题直接在当前终端作答：单选输一个编号，多选用逗号分隔。答错会显示解释，然后重新提示；答对才进下一题。

```text
Enter  验证 / 开始 quiz
h      提示
c      概念 + 阅读
p / n  上一题 / 下一题
l      题目选择器
r / f  硬重置 / 快速重置
q      退出，保留容器
x      退出并销毁容器
```

## 题库结构

```text
clablings.yaml                 # 题库清单
chapters/<chapter-id>/
  chapter.yaml                 # 章节元数据、目标、拓扑
  concept.zh.md                # 中文主稿
  concept.en.md                # 英文摘要
  reading.en.yaml              # RFC / 文档阅读切片
  topology.clab.yml            # 可选：共享实验拓扑
  exercises/<exercise-id>/
    exercise.yaml              # 题目、提示、断言 / quiz
    README.zh.md               # 中文实验说明
    README.en.md               # 英文摘要
```

题型：

- `quiz`：概念自检，不部署容器。
- `config-fix`：在运行中的拓扑里修配置，用断言判定。
- `code-implement`：写代码、构建、下发到节点运行。

中文是主稿，英文是摘要，不要求逐句对应；详细写作规范在本地维护。

## 章节

| 章节 | 题型 | 触发方式 | 这一章讲什么 |
|---|---|---|---|
| 01-vlan-trunk | quiz + 运行态 config-fix（含抓包） | Enter | 从“为什么要 VLAN”讲到 access/trunk/native VLAN 的收发包行为，观察无标签/带标签帧（Linux bridge） |
| 02-stp | quiz + 文件驱动 config-fix | 哨兵 + Enter | 理解 STP 根桥选举和环路防护，调整优先级让核心交换机成为根 |
| 03-lacp | quiz + 文件驱动 config-fix | 哨兵 + Enter | 理解链路聚合和 LACP 协商，修复 active/passive 让 LAG 起来（SR Linux） |
| 04-mlag | quiz（概念章，无实验） | 答题推进 | 理解 MLAG/vPC、脑裂和 EVPN 多归，顺便对比堆叠 |
| 05-bgp-basics | quiz + 运行态 config-fix（含抓包） | Enter | 理解 eBGP 会话建立和状态机，修 remote-as、协商 hold time（FRR） |
| 06-bgp-messages | quiz + 运行态 config-fix（含抓包） | Enter | 理解 BGP 报文格式，修未通告（ebgp-requires-policy），拆 UPDATE/NOTIFICATION（FRR） |
| 07-bgp-attributes | quiz + 运行态 config-fix | Enter | 理解 BGP 选路和属性，用 LOCAL_PREF/AS_PATH 改变选路（FRR） |
| 08-bgp-troubleshoot | quiz + 运行态 config-fix（含抓包） | Enter | BGP 排错：卡 Active、bad peer AS、iBGP next-hop-self（FRR） |
| 09-bgp-code | code-implement（C） | 哨兵 + Enter | 用 C 写一个最小 BGP speaker：OPEN/KEEPALIVE 建会话、UPDATE 通告前缀（FRR 对等） |

## 路线

M1 交换主线已完成：VLAN/Trunk → STP/RSTP → LACP → MLAG/EVPN-MH（概念）。

BGP 路线已完成：会话建立/状态机 → 报文格式 → 路径选择 → 排错 → C 实现最小 speaker。

后续计划：

- 完整 EVPN-MH 实验（underlay + iBGP EVPN + ESI + 双归主机 LAG）。
- 更多 M2 Overlay（VXLAN、Geneve、EVPN 控制面）和 M3 路由主线章节。

## 参与贡献

- 内容问题、翻译问题、拓扑问题：提 issue，选“Content issue”模板。
- 想改题或加章节：先看内容规范，提 PR 时说明改了哪一章、哪些断言。
- 安全问题请报告到 [clablings 的 SECURITY](https://github.com/tianyuxue/clablings/blob/main/SECURITY.md)，不要开公开 issue。

## 许可证

题库内容采用 [CC BY-SA 4.0](LICENSE) 许可。转载、改编或再发布时请署名，并以相同方式共享。

代码、命令行工具和 `clablings` 本身使用 [Apache-2.0](https://github.com/tianyuxue/clablings/blob/main/LICENSE)。
