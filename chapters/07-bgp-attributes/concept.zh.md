# BGP 属性与选路

## 场景

一台路由器从两家运营商学到同一前缀。它最终走哪条不是碰运气：BGP 按固定顺序
比较一系列属性，运维者可以设置其中一些来引导流量。

## 术语

- **Weight**：Cisco/FRR 本机值，最先比较；不发给对等体。
- **LOCAL_PREF**：本 AS 对某路由的偏好，只在 iBGP 中传递。
- **MED（MULTI_EXIT_DISC）**：提示相邻 AS 使用哪个入口；可选且非传递。
- **最优路径（Best path）**：BGP 发言者按顺序比较属性后安装并通告的那一条。
- **AS_PATH prepending**：把本 AS 号重复加入，使路径看起来更长、更不被优先。

## 痛点

同一前缀有两条路径时，走"错"的一边会带来费用与时延，而在不了解比较顺序前，
这个选择显得随意。

## 为什么直觉方案不行

不懂得优先级就调下游度量可能毫无作用：LOCAL_PREF 先于 AS_PATH 与 MED 比较，
所以一旦 LOCAL_PREF 已定，MED 再低也赢不了。

## 机制

BGP 依次比较：Weight、LOCAL_PREF、本地产生、AS_PATH 长度、ORIGIN、MED、
eBGP 优于 iBGP、IGP 度量，最后才是打破平局项。这里涉及两个旋钮：
`local-preference`（按邻居、入向）与 `as-path prepend`（出向）。MED 只在
来自同一邻居 AS 的路径之间比较。

## 配置与查看

在 r1 上：
```
ip route get 10.2.2.100
vtysh -c 'show bgp ipv4 unicast'
```

## 常见问题

- 我把 MED 调低了为什么没生效？MED 只在同一邻居 AS 内比较；跨 AS 默认忽略。
- 为什么对端看不到 LOCAL_PREF？LOCAL_PREF 是本 AS 内部属性，不跨 eBGP 发送。
- 怎么让一条路径更不被优先？在出向 UPDATE 上 prepend 本 AS，使 AS_PATH 更长。
