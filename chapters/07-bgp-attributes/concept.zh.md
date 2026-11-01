# BGP 属性与选路：同一前缀，两条路，走哪条？

## 先看现象

r1 从两家上游各学到一条 10.2.2.0/24。两条路都通，ping 都通。可流量偏偏走了时延更高的那条，账单也更贵。

你去调其中一条的 MED，把它压到最低。会话重置了，路由表却没动。再查一遍，选中的还是原来那条。

这不是 BGP 随机。它每次只认一个结果，而这个结果由一串属性按固定顺序比出来。想改路，得先知道它先看什么。

## 问题在哪

先问三个问题。

两条路径都没配过属性时，BGP 凭什么选？它总得有个先后。

如果我只想影响自己这一台路由器，该动哪个属性？如果我想让对端也改主意，又该动哪个？

还有一个更隐蔽的：为什么有的属性改完，对端完全看不到？

答案分两层。第一层是比较顺序，谁排在前面，谁先决定胜负。第二层是作用范围，属性能在本机、本 AS 还是跨 AS 生效。顺序决定话语权，范围决定这句话能传多远。

## 几个绕不开的术语

- **路径属性（path attribute）**：跟着每条 BGP 路由走的一组参数。选路时，BGP 就是拿这些参数逐项对比。
- **最优路径（best path）**：同一前缀有多条可用路径时，BGP 按顺序比完，最后装进路由表并通告出去的那一条。
- **Weight**：Cisco/FRR 自己的本机值，数值越大越优先，排在最前面。它只影响本机，不会发给任何对等体。
- **LOCAL_PREF**：本 AS 对某条路由的偏好，数值越大越优先。它只在 iBGP 里传，eBGP 对等体收不到。
- **iBGP**：同一个 AS 内两台路由器之间的 BGP 会话。
- **eBGP**：不同 AS 的两台路由器之间的 BGP 会话。
- **AS_PATH**：路由从源 AS 到本 AS 经过的 AS 号列表。路径越短，越优先。
- **AS_PATH prepending**：在出向 UPDATE 里把本 AS 号重复加几遍，让对端看到的 AS_PATH 变长。
- **MED（MULTI_EXIT_DISC）**：给邻居 AS 的提示，告诉它从哪个入口进来更合适。数值越小越优先。它是 optional non-transitive，可选，而且不继续往下一个 AS 传。
- **ORIGIN**：路由进入 BGP 的方式，分 IGP、EGP、incomplete 三种，用来在长度相同时打破平局。
- **本地产生（locally originated）**：本机自己注入的路由，比如用 network 语句宣告。它在比较顺序里排得很靠前。

属性除了有名字，还有类别。ORIGIN、AS_PATH、NEXT_HOP 是 well-known mandatory：UPDATE 报文里只要带了 NLRI（网络层可达信息，可以理解成路由前缀），就必须带上它们。MED 是 optional non-transitive。LOCAL_PREF 不在 mandatory 里，但它只在 iBGP 内传递，这个范围决定了为什么对端看不到它。

## 机制：一条固定的比较流水线

BGP 拿到同一前缀的多条路径，从第一项开始比，分出胜负就停。FRR 和 Cisco 的顺序一样：

1. Weight，大者胜
2. LOCAL_PREF，大者胜
3. 本地产生，优先
4. AS_PATH 长度，短者胜
5. ORIGIN，IGP 优于 EGP，EGP 优于 incomplete
6. MED，小者胜
7. eBGP 路径优于 iBGP 路径
8. 到下一跳的 IGP 度量（内部网关协议算出的开销），小者胜
9. 最后才用 router-id 这类平局项

记住前四项，实验里绝大多数选择都能解释。

Weight 排第一，但它走不出本机。换一台路由器，这个值就没了。

LOCAL_PREF 排第二，作用范围是本 AS。你在 r1 上给从 r2 学来的路由设 200，r1 立刻更愿意走 r2。可这个值不会出现在发给 r2 或 r3 的 UPDATE 里。

AS_PATH 排第四。它记录的是路径长度，不是带宽，也不看时延。两条路径的 AS_PATH 都只有一个 AS 号时，它分不出高下，比较会继续往下走。

MED 排第六，而且有一个前提：默认只在来自同一个邻居 AS 的路径之间比较。r1 从 AS65002 和 AS65003 各学到一条，这是两个不同的邻居 AS，MED 再低也不会被拿来对比。想强行跨 AS 比较，得开 `bgp always-compare-med`，那是另一回事。

在本章的基础配置里，两条路径的 AS_PATH 都只有一个 AS 号，ORIGIN 都是 IGP，MED 都是 0，eBGP 对 eBGP，IGP 度量也一样。前面几项全打平，最后按 router-id 决出胜负。谁小谁赢。这也解释了你看到的现象：明明两条路差不多，选中的却总是 router-id 更小的那台。

## 动手配一下：两个方向，两种属性

想让 r1 更愿意走 r2，最直接的办法是在入向抬高 LOCAL_PREF。它排在 AS_PATH 前面，改完立刻生效：

```sh
vtysh -c 'conf t' -c 'route-map FROM_R2 permit 10' -c 'set local-preference 200' -c 'router bgp 65001' -c 'neighbor 10.1.12.2 route-map FROM_R2 in'
```

反过来，如果你在 r2 上，想让 r1 少走自己这条路，就在出向把 AS_PATH 拉长：

```sh
vtysh -c 'conf t' -c 'route-map PAD_65002 permit 10' -c 'set as-path prepend 65002 65002' -c 'router bgp 65002' -c 'neighbor 10.1.12.1 route-map PAD_65002 out'
vtysh -c 'clear bgp *'
```

LOCAL_PREF 改的是本机路由表（RIB），马上见效。prepend 改的是发出去的 UPDATE，要等下一次更新，或者手动重置会话，对端才看得到。

## 看一眼路由表

在 r1 上确认它到底选了谁：

```sh
ip route get 10.2.2.100
vtysh -c 'show bgp ipv4 unicast'
```

第一条命令看转发面：下一跳是 10.1.12.2 还是 10.1.13.2。第二条看 BGP 表：两条路径各自的 AS_PATH、LOCAL_PREF、MED，以及谁被标成 best。

## 几个常见坑

### MED 调低了，为什么没反应？

先看两条路径是不是来自同一个邻居 AS。不同 AS 之间，MED 默认不参与比较，调多低都没用。

### 对端为什么看不到我设的 LOCAL_PREF？

LOCAL_PREF 只在本 AS 内传。eBGP 会话另一头在别的 AS，收不到这个属性。想让对端改选路，得用 AS_PATH 这类会跨会话传的属性。

### prepend 配完了，路由怎么还没变？

属性要随下一次 UPDATE 发出去。等不及就 `clear bgp *` 重置会话。

### 两条路径看起来一模一样，为什么选了这一条？

一路比到最后都平手时，router-id 更小的赢。改 router-id，或者在前面某一项上拉开差距，结果就会变。

### Weight 设了，为什么换台设备就不生效？

Weight 只在本机有效，不进 UPDATE，也不跨会话。它适合做单机上的临时偏好。
