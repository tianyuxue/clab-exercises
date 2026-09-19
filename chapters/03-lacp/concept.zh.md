# 链路聚合（LACP）

## 为什么

没有 STP 的冗余链路就是环路；有了 STP，除一条外的冗余链路都被**阻塞**，你为用不上
的带宽付了钱。链路聚合两者兼得：把多条物理链路捆绑成一条逻辑链路，并行承载流量，
并在成员故障时存活。

## 是什么

**LAG**（链路聚合组，也叫 PortChannel/bond）是由多个成员组成的逻辑接口。交换机会把
每条流哈希到某个成员，因此单条流仍不能超过单链路速率，但多条流可以共享整个捆绑。
**LACP**（IEEE 802.1AX）与对端协商捆绑：双方就"哪些链路是成员、是否健康"达成一致。

## 怎么做

- 成员通过 id（`aggregate-id`）引用 LAG；LAG 本身是路由接口（`lag1`），带子接口与 IP。
- **LACP 模式**：至少一侧必须是 **ACTIVE** 才会发送 LACPDU；**PASSIVE** 只回应。
  两侧都 PASSIVE 永远不会协商。
- **admin-key**（以及 system id/priority）必须一致，成员才能加入；`min-links` 保证
  成员不足时 LAG 保持 down。
- SR Linux：用 `sr_cli` 配置；`show lag` 报告聚合状态、成员状态与 `oper-down-reason`；
  经 LAG 的 ping 要指定 default network-instance。

## 精读

读懂 LACP 帧如何协商成员。然后回答：为什么两个 PASSIVE 接口永远无法形成捆绑？
min-links 又是防什么的？
