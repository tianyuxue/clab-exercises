# 01_access_vlan

`sw` 上运行着一个开启 VLAN filtering 的 Linux bridge。`h1`（10.0.1.1/24）与
`h2`（10.0.1.2/24）同属一个网段，但两个 access 端口的 PVID 不同，所以互相不通。

## 修复步骤

在本章目录另开一个终端，直接配置正在运行的交换机（`make debug` 或 `docker exec`）：

- `docker exec <sw> bridge vlan show` —— 查看各端口的 PVID
- 把 `eth1` 与 `eth2` 都改为 VLAN 10 且 `pvid untagged`，例如
  `docker exec <sw> bridge vlan del dev eth2 vid 20 && docker exec <sw> bridge vlan add dev eth2 vid 10 pvid untagged`

改动立即生效。按 Enter 验证；按 `f`（fast reset）会重新注入故障，方便从头再来。
