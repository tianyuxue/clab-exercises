# 链路聚合（LACP）

## 场景

一台服务器需要超过单条 1 Gbit/s 链路的带宽，并且在一根线缆或某个交换机端口故障时仍要照常
工作。它的操作系统可以用 LACP 把多条链路捆成一条。你把服务器的两根线缆接到交换机上，两端
都配好这个捆绑。

## 术语

- **LAG**（链路聚合组，也叫 PortChannel 或 bond）：由多条物理**成员**链路组成的*逻辑*
  接口。
- **成员（member）**：属于某个 LAG 的一条物理链路。
- **流哈希（flow hashing）**：交换机对每条流按报文头部字段做哈希，选出一条成员。因此一条
  流（每个方向）只走一条成员。
- **LACP**（802.1AX）：两端用来协商“哪些链路是成员、链路是否健康”的协议。
- **Active / passive**：**active** 一侧主动发送 LACP 报文（`LACPDUs`）；**passive** 一侧只
  应答。至少一侧必须是 active。
- **admin-key**：成员要加入同一个 LAG 必须达成一致的标识。
- **min-links**：LAG 保持 up 所需的最少可用成员数。

## 痛点所在

单条链路既没有冗余，速率也只有它自己那么高。若在*不聚合*的情况下再加一条链路，STP 会把它
阻塞，实际仍然只跑一条。而如果把服务器的两条链路接到**两台独立交换机**上，它的 LACP 就要
同时面对两个不同的伙伴，根本凑不成一个捆绑。

## 为什么想当然的修法行不通

- **静态 bond（不用 LACP）**：即便对端配错，链路照样会 up；某个“半坏”的成员仍会继续承载
  （并丢弃）流量，因为没有协议去校验健康度。
- **两台独立交换机**：每台交换机都是独立的 LACP 伙伴、各有自己的 System ID，服务器看到的
  是两个单链路捆绑，而不是一个双链路捆绑。要让这种方式成立，得靠 MLAG/EVPN-MH（下一章）。

## 核心机制

**LAG** 把多条成员链路呈现为一个逻辑接口，于是一份 IP 配置、一条路由就能覆盖它们全部。流量
按流哈希分摊到各成员，既拿到聚合带宽，也获得成员故障时的韧性。

**LACP** 让这个捆绑保持“诚实”：两端交换 LACP 报文，列出各自认为属于该捆绑的成员及其状态。
只有两端达成一致（同一个 LAG、兼容的 **admin-key**）且链路健康，成员才会加入。成员故障时会
退出捆绑，流量重新哈希到其余成员——前提是 **min-links** 仍然满足。

## 配置与查看

在 SR Linux 上配置 LAG（成员通过 id 引用它；LAG 本身是路由接口），再用 `show lag` 查看：

```sh
# 在交换机上以 shell 脚本形式，把 CLI 命令喂给 sr_cli
sr_cli -d <<'EOF'
enter candidate
set / interface ethernet-1/1 ethernet aggregate-id lag1
set / interface ethernet-1/2 ethernet aggregate-id lag1
set / interface lag1 lag lag-type lacp
set / interface lag1 lag lacp lacp-mode ACTIVE
set / interface lag1 subinterface 0 ipv4 address 10.0.0.1/30
set / network-instance default interface lag1.0
commit now
EOF

sr_cli -d "show lag"                       # lag 是否 up？成员是否 up？oper-down-reason？
sr_cli -d "ping -c 2 10.0.0.2 network-instance default"
```

关键输出是 `show lag`：`lag1` 是否 **up**、每个成员的 `oper-state`，以及未 up 时的
`oper-down-reason`。

## 常见问题

- **两侧都 passive**：没人发送 LACP 报文，捆绑保持 down，原因为 `no-active-links`——这
  正是本题注入的故障。
- **admin-key 不一致**：成员无法加入捆绑，原因为 `lacp-down`。
- **一条流只走一条成员**：单条流永远跑不过单成员速率；聚合有利于多条流，而不是某一条。
- **min-links**：可用成员不足时会刻意让 LAG 保持 down，避免降级的捆绑继续转发。
