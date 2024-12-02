---
title:  "[redis] 执行流程"
subtitle: "redis是单线程的，数据以键值对形式存储在内存"
tags:  ["redis"]
date:  "2024-10-27"
categories: ["redis"]
series: ["database"]
---
## 四、执行流程

1. 内存结构
2. 核心执行是单线程
3. 多线程负载一些异步任务

### 1.Redis在内存中是怎么存储的

redis是内存存储，将数据放在redis时，都是以键值对形式存到内存

#### 数据库结构

redisDb代表Redis数据库结构，各种操作对象，都是存储在dict数据结构里

```C
// redisDb 结构
type struct redisDb {
    dict *dict;           //字典
    dict *expires;        // 过期键
    dict *blocking_keys;
    dict *ready_keys;
    dict *watched_keys;
    int id;
    long long avg_ttl;
    list *defrag_later;
} redisDb;

// dict 结构
typedef struct dict {
    dictType *type;
    void *privdata;
    dictht ht[2];
    long rehashidx;
    unsigned long iterators;
} dict;
```

redisDb即数据库对象，指向了数据字典，字典包含我们平常存储的k-v数据，v支持任意redis对象

![](https://rt5bap83jl.feishu.cn/space/api/box/stream/download/asynccode/?code=ZjUwNmMwNDdlZTRiYmE0ODNjZjNlYWE1M2U2ZjRhZmZfMVhzNEFiWk0xQ2tYMXh0T21yQ045OGgwOVVLSzhDV0NfVG9rZW46VkdtbmJwMEZSb0tqcHF4ckhqVGNrTHI4blBkXzE3MjE4NDE0MjU6MTcyMTg0NTAyNV9WNA)

在增加、查询、更新、删除的操作后，分别在内存存储是怎么体现的？

#### 增删改查在Redis内存中的体现

- 添加数据

即添加键值对，添加到dict结构字典中，Key必须为String对象，value为任何类型的对象

添加数据后，会在redisDb里字段dict上添加dict对象

- 查询数据

直接在dict找到对应的key，即完成查询

- 更新数据

对已经Key对象的任何变更操作，都是更新

- 删除数据

删除即把key和value从dict结构里删除

#### 过期键

Redis可以设置过期键，到达一定时间，这些对象会被自动过期并回收

**过期键存储在****expires****字典上，**expires字典中，value就是过期时间

在redisDb中，dict和expires中Key对象，实际都是存储String对象指针，两个的key都会指向内存相应的字符串地址



### 2.Redis是单线程？还是多线程？

redis是一个能高效处理请求的组件

核心处理逻辑，Redis一直都是单线程，其他辅助模块会有一些多线程、多进程的功能，例如：复制模块用的多进程；某些异步流程从4.0开始用多线程；网络I/O解包从6.0开始用多线程；

> 核心处理逻辑：Redis在处理客户端的请求时，包括获取（socket写）、解析、执行、内容返回等都是由一个顺序串行的主线程处理，这就是所谓的单线程

#### Redis为什么选择单线程

redis的定位是内存k-v存储，是做短平快的热点数据处理，一般来说执行会很快，执行本身不会成为瓶颈，瓶颈通常在网络I/O，处理逻辑多线程并不会有太大收益

同时Redis本身秉持简洁高效的理念，代码的简单性、可维护性是redis一直依赖的追求，执行本身不应该成为瓶颈，而且多线程本身也会引起额外成本

#### 1.多线程引入的复杂度是极大的

1. 多线程引入后，redis原来的顺序执行特性就不复存在，为了事务的原子性、隔离性，redis就不得不引入一些很复杂的实现

2. redis的数据结构是极其高效，在单线程模式下做了很多特性的优化，如果引入多线程，那么所有底层数据都要改为线性安全，这很复杂

3. 多线程模式使得程序调试更加复杂和麻烦，会带来额外的开发成本及运营成本


#### 2.多线程带来额外的成本

除了引入复杂度，多线程还会带来额外成本，包括

1. 上下文切换成本，多线程调度需要切换线程上下文，这个操作先存储当前线程的本地数据，程序指针，然后载入另一个线程数据，这种内核操作的成本不可忽略

2. 同步机制的开销，一些公共资源，在单线程模式下直接访问就行，多线程需要通过加锁等方式进行同步

3. 一个线程本身也占据内存大小，对redis这种内存数据库来说，内存非常珍贵，多线程本身带来的内存使用的成本也需要谨慎决策


#### 总结

多线程会引入额外的复杂度和成本，而redis是追求简洁高效的存储组件，而且事实也证明，虽然redis是单线程处理架构，redis性能还是经受住了考验



### 3.Redis单线程为什么能这么快

#### Redis单线程

Redis核心的请求处理是单线程，但是Redis却能使用单线程模型达到每秒数万级别的处理能力，这是Redis多方面极致设计的一个综合结果

1. Redis的大部分操作在内存上完成，内存操作本身就特别快

2. Redis选择了很多高效的数据结构，并做了很多优化，比如ziplist，hash，跳表有时候一种对象底层有几种实现以应对不同场景

3. redis采用了多路复用机制，使其在网络IO操作中能并发处理大量的客户端请求，实现高吞并量


#### I/O可能的潜在点

Redis是完全在内存中处理数据，所以我们应该考虑瓶颈是I/O





##### I/O多路复用

简单理解，就是I/O操作触发的时候，就会产生通知，收到通知，再去处理通知对应的事件，正对I/O多路复用，Redis做了一层包装，叫Reactor模型

本质就是监听各种事件，当事件发生时，将事件分发给不同的处理器

![](https://rt5bap83jl.feishu.cn/space/api/box/stream/download/asynccode/?code=MWY3ZDk5ZWZmZmM1OTE2ZjQyNzUwYjc4OWVhODdkOTdfTDdvMjdnUjJZZzBtb21iTnFBZVFhaXBFbEk0clhhOWNfVG9rZW46R2tVcWJ3WFBnb1VXYWh4cmRrdmNYTVV3bkRmXzE3MjE4NDE0MjU6MTcyMTg0NTAyNV9WNA)

这样就不会阻塞到某个操作上，充分发挥性能，可以说I/O多路复用让redis单线程有了较大的并发度，这里是并发，不是并行，这种模式下，Redis单核的性能可以是被充分利用

> http://t.csdn.cn/nsVup
>
> http://t.csdn.cn/RbE7R

#### 总结

Redis单线程还快的原因有3点：内存操作、高效的数据结构、I/O多路复用。



### 4.Redis多线程是怎么回事？

#### Redis多线程模型

redis一开始就是基于单线程模型，Redis里所有的数据结构都是非线程安全，规避了数据竞争问题，使得Redis对各种数据结构的操作非常简单

> redis选择单线程的核心原因是Redis都是内存操作，CPU处理都非常快，瓶颈更容易出现在I/O而不是CPU，所以选择了单线程模型

随着数据量的增大，redis的瓶颈更容易出现在I/O而不是CPU

因为上述情况，Redis选择了引入多线程来处理网络I/O，这样即保持了Redis核心的单线程处理价格，又引入了多线程解决提高网络I/O的性能



### 5.Redis可以存多少数据，满了怎么淘汰？

redis是基于内存存储的

使用`maxmemory` 配置，默认是注释掉的也就是默认值是0，在32为操作系统默认是3G，最大支持4GB

而现在的机器基本都是64位，不做限制内存的使用，maxmemory支持个单位

- Maxmemory 1024 (byte)

- Maxmemory 1024KB

- Maxmemory 1024MB

- Maxmemory 1024GB


当Redis存储超过这个配置值，则触发Redis内存淘汰

#### 怎么淘汰

Redis有两种淘汰策略，一个是noeviction，默认是这种策略，此时如果内存达到maxmemory，则写入操作会失败，但不会淘汰已有数据

![](https://rt5bap83jl.feishu.cn/space/api/box/stream/download/asynccode/?code=ODEyODNhNGM2MTQxMmI1ZGIyOGZiN2VmMjk1MDFkMGZfV2pQRXVpNGkyczVPZ2J1RGJzTWlOcE95MzdBVmlzaGJfVG9rZW46QnFaamJaZFc0b3BFY2R4OVhjNGNtandQbmplXzE3MjE4NDE0MjU6MTcyMTg0NTAyNV9WNA)

第二个是多种淘汰策略，主要支持LRU、LFU、RANDOM、TTL这几个方式：

- lru：根据LRU（least recently used，最近少使用）算法尝试回收最长时间未使用的

- lfu：根据LFU（least frequently use，不常使用）驱逐最不常用的键，lfu是在4.0引入的

- random：回收随机的键使得新添加的数据有空间存放

- ttl：回收过期集合的键，并且优先回收存活时间（TTL）较短的键，使得新添加的数据有空间存放


这四种策略，可以选择时volatile，也就是设置过期时间的key，或者allkeys，即全部的key，所以一共有8种淘汰策略

#### 选择哪种淘汰策略

淘汰算法根据业务需求决定，

#### 淘汰时机：

什么时候触发淘汰？实际上每次运行读写命令的时候，都会调用processCommand函数，processCmmand函数会调用freeMemoryIfNeeded，这时候会尝试释放一定内存，使用配置的策略

### 6.内存淘汰算法--LRU

LRU是一种非常流行的资源淘汰算法，为了减少内存消耗，redis使用了近似LRU

#### LRU算法是什么？

最近最久未使用，即记录每个key的最近访问时间，维护一个访问时间的数据

#### Redis用LRU算法有什么问题？

维护一个顺序链表，对Redis来说，内存是宝贵的，所以当数据量变大的时候，这个链表对Redsi来说就是巨大的成本

所以，Redis使用**近似LRU算法**

#### 算法概述

在LRU模式，redisObject对象中lru字段存储的是key被访问时Redis

的时钟server.lruclock，当key被访问时，Redis会更新这个key的RedisObject的lru字段

> Redis为了保证核心单线程服务性能，缓存了Unix操作系统时钟，默认每100毫秒更新一次，缓存的值是Unxi时间戳取模2^24

近似LRU算法