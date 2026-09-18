# 01_mtu_mismatch（运行态排错题）

本题目**不使用文件监听/哨兵**。故障已由章节拓扑在部署时注入。

## 修复路径

在另一个终端执行 `make debug` 打开 clab-tui，进入 r1，任选其一：

- `ip link set eth1 mtu 1500`
- `vtysh` → `configure terminal` → `interface eth1` → `ip ospf mtu-ignore`

修复后 OSPF 需要数秒重新协商（改动 MTU 会重置邻居），等待 `show ip ospf neighbor` 回到 `Full` 后，
回到 `clablings watch` 终端，按 **Enter** 强制验证。
