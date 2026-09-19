# 01_access_vlan

`sw` 上运行着一个开启 VLAN filtering 的 Linux bridge。`h1`（10.0.1.1/24）与
`h2`（10.0.1.2/24）同属一个网段，但两个 access 端口的 PVID 不同，所以互相不通。

## 修复步骤

在本章目录另开一个终端执行 `make debug`（或直接用 `docker exec`）查看网桥，
然后在宿主机上编辑 `sw/vlan.sh`：

- `docker exec <sw> bridge vlan show`
- 把 `eth1` 与 `eth2` 都放入 VLAN 10，并使用 `pvid untagged`
- 删除 `I AM NOT DONE` 行

保存后 `clablings watch` 会自动把文件复制进 `sw` 并执行 reload 脚本；也可以按
Enter 强制验证。
