# 用 C 写一个最小 BGP speaker

## 场景

你想看清一个对端要少到什么程度才能和真实路由器交换路由。与其依赖库，不如亲手
拼出这些字节。

## 术语

- **报文头部（Message header）**：16 字节 marker（全 1）、2 字节 length（含头部）、1 字节 type。
- **OPEN**：第一条报文；这里是 version 4、my AS、hold time 与 BGP identifier。
- **KEEPALIVE**：仅 19 字节头部，用于维持会话。
- **UPDATE**：撤销路由、路径属性（ORIGIN、AS_PATH、NEXT_HOP），然后是 NLRI。
- **FSM（有限状态机）**：你的程序经历的状态：OPEN 与 KEEPALIVE 之后进入 Established。

## 痛点

读懂格式和自己发出一个能被另一套协议栈接受的字节流不是一回事：字段顺序、字节序与长度
计算都必须精确。

## 为什么直觉方案不行

只发 OPEN 不读对端 OPEN，或不发 KEEPALIVE，会让会话卡住、或让 Hold Timer 超时，对端
随即拆链。

## 机制

BGP 跑在 TCP 179 端口上。你发出 OPEN，收到对端 OPEN，交换 KEEPALIVE，会话进入
Established。UPDATE 随后承载带路径属性的 NLRI：

```
Marker(16) | Length(2) | Type(1) | Withdrawn Routes Length(2) | Path Attributes | NLRI
```

所有多字节字段均为网络序。

## 配置与查看

在 r1 上：
```
vtysh -c 'show bgp summary'
vtysh -c 'show bgp ipv4 unicast'
```

你的程序输出在 speaker 节点：
```
cat /tmp/bgp.log
```

## 常见问题

- 为什么 marker 要全 1？头部长度固定；规范把 marker 定义为全 1，使 length 字段能定位下一条报文。
- Length 含头部吗？含，它计整条报文；KEEPALIVE 为 19。
- 为什么每 hold/3 发一次 KEEPALIVE？协商出的 Hold Time 内收不到任何东西就会过期；取其三分之一是推荐余量。
