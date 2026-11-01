# 01_fix_lacp

先看现象：`srl1` 和 `srl2` 之间拉了两条线，捆成 `lag1`，跑 LACP。可 `show lag` 里 `lag1` 是 down，两个成员都没进转发集合，`10.0.0.1/30` 也 ping 不通 `10.0.0.2`。

## 问题在哪

看 `oper-down-reason`，写的是 `no-active-links`。两台交换机的 `lacp-mode` 都是 PASSIVE，谁也不主动发 LACPDU，都在等对方先开口。链路物理上 up，协议上一直没谈成。

## 抓包或观察

先确认故障点，别急着改：

```sh
docker exec <srl1> sr_cli -d "show lag"
```

盯三样：`lag1` 的状态、每个成员的 `oper-state`、还有 `oper-down-reason`。原因指向 `no-active-links`，就说明缺一个主动方。

## 动手修

把 `srl1` 改成 ACTIVE，让它在链路上先发 LACPDU：

```sh
docker exec <srl1> sr_cli -d "enter candidate; set / interface lag1 lag lacp lacp-mode ACTIVE; commit now"
```

`commit now` 之后马上生效，不用重启。再跑一次 `show lag`，`lag1` 应该变成 up，两个成员都进组。`srl2` 保持 PASSIVE 没问题，LACP 只要求一侧主动。

按 Enter 验证；按 `f` 重新注入故障。
