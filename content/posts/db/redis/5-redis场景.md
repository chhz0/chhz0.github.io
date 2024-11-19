---
title:  "[redis] 场景"
subtitle: "redis的使用场景——缓存和分布式锁"
tags:  ["redis"]
date:  "2024-10-29"
categories: ["redis"]
---
# 六、场景
## 1.缓存

Redis由于性能高效，通常可以做数据库存储的缓存，比如给Mysql做缓存

通常业务都满足二八原则，80%的流量在20%的热点数据上，所以缓存可以很大程度提高系统的吞吐量

### 1.1缓存基础

一般而言，缓存分为服务器缓存，客户端缓存

缓存一般有以下几种模式：

1. 旁路缓存模式：

2. 读穿透模式：

3. 写穿透模式：

4. 异步缓存写入模式：


#### 旁路缓存模式（适用于读多写少）

Cache Aside，旁路缓存模式，是**最常见的模式**，应用服务把缓存当作数据库的旁路，直接和缓存交互

- 读操作：服务端收到查询请求，先查询数据是否在缓存上，如果在，就用缓存数据直接打包返回，如果不存在，就去数据库查询，并放到缓存

- 写操作：cache aside模式一般先更新数据库，再直接删除缓存（更新相比删除更容易造成时序性问题）


适用于读多写少的场景，缺点是可能会出现缓存和数据库不一致的情况

> 这里的写操作，更新相比删除更容易造成时序性问题，具体举例：线程1更新mysql -> 线程2更新mysql -> 线程2更新缓存 -> 线程1更新mysql，这样就出现了时许性问题

该模型的缺点：

可能出现缓存和数据库不一致的情况，具体见：[数据库和缓存如何保证一致性？](https://xiaolincoding.com/redis/architecture/mysql_redis_consistency.html#%E5%85%88%E6%9B%B4%E6%96%B0%E6%95%B0%E6%8D%AE%E5%BA%93-%E8%BF%98%E6%98%AF%E5%85%88%E6%9B%B4%E6%96%B0%E7%BC%93%E5%AD%98)

#### 读穿透模式

与cache aside模式的区别主要在应用服务不再与缓存直接交互，而是直接去访问数据服务。

这里的数据服务理解为一个**代理服务，**用它来访问缓存和数据库

![](https://rt5bap83jl.feishu.cn/space/api/box/stream/download/asynccode/?code=NGRhNWI5ZGY3OGFiNjlkNTc3NTQ1MTdjMGJiOTg2YmJfT09iTTdsU1pjbnNsR0dlU2ZvMEprMGlDa1hjd0l1QldfVG9rZW46TmE5MGJGTW52b3RWbHN4SmZadmM2dXZTbjJnXzE3MjE4NDE0OTU6MTcyMTg0NTA5NV9WNA)

相比于旁路缓存模式，读穿透模式的优势是缓存对业务是透明的；缺点是缓存命中的性能不如旁路缓存模式，会多一层服务调用

#### 写穿透模式

WriteThrough做了一层封装：有缓存服务先写入Mysql，再同步写入Redis，这样及时加载或更新了缓存数据（理解为，应用程序由一个单独的访问源，而存储服务自己维护访问逻辑）

![](https://rt5bap83jl.feishu.cn/space/api/box/stream/download/asynccode/?code=YWE5MTA1Y2MyNWE3OTYyY2I3Y2FmZjNiM2VmN2M3NDBfV1JIVlJVR01KN3VCakM4WVZ2REpFeXRtb21nb1ZYa0FfVG9rZW46U0F6emJXa3JFb29tSHV4OWh6cmNFdGpVbnllXzE3MjE4NDE0OTU6MTcyMTg0NTA5NV9WNA)

在使用WriteThrough时，一般都配合使用ReadThrough来使用

适用情况：

- 对缓存及时性要求更高

- 不能忍受数据丢失和数据不一致


#### 异步缓存写入模式（Write-Behind）

write-Behind和Write-Through相同点是都是写入时会更新数据库、也会更新缓存

不同点是：Write-Behind是先写缓存，后**异步**把数据一起写入数据库

数据库写操作可以用不同的方式完成：

1. 收集写操作并在某个时间点慢慢写入

2. 合并几个写操作成为一个批量操作，一起批量写入


异步写操作极大降低了请求延迟，并减轻了数据库的负担，但是代价是安全性不够，如果缓存中的数据还没写入数据库，存储服务发生了崩溃，那么数据就丢失了

### 1.2缓存异常

#### 缓存穿透

- 问题背景


缓存穿透是指**缓存和数据库都没有的数据，**而用户不断发起请求。

在流量大的时候，DB可能就挂掉了，要是有人利用不存在的key频繁攻击我们的应用，这就是漏洞

- 解决方案


1. 接口层增加校验，如用户鉴权校验，id做击穿校验，id<=0的直接拦截

2. 从缓存取不到的数据，在数据库中也没有取到，这时可以将key-value对写成key-null，缓存有效时间写短点，例如30s

3. 布隆过滤器：bloomfilter类似于一个hash set，用于快速判断某个元素是否存在于集合中，关键在于hash算法和容器大小


> 布隆过滤器：
>
> 原理：布隆过滤器底层是一个64位的整型，将字符串用多个Hash函数映射不同的二进制位置，将整型中对应位置设置为1
>
> 优点：空间、时间消耗都很小
>
> 缺点：结果不完全准

#### 缓存击穿

- 问题背景


缓存击穿是指**缓存中没有但数据库中有的数据**（一般缓存时间到期），这时由于并发的用户过多，同时读缓存没有数据又同时查询数据库，引起数据库压力瞬时增大

- 解决方案


1. 热点数据支付续期，持续访问的数据不断续期，避免因为过期失效而被击穿

2. 发现缓存失效，重建缓存加互斥锁，当线程查询缓存发现缓存不存在就会尝试加锁，线程抢锁，拿到锁的线程进行查询数据库，然后重建缓存


#### 缓存雪崩

- 问题背景


指大量的应用请求因为异常无法在Redis缓存中处理，直接打到数据库。这里的异常就是：**缓存中数据****大批量****到过期时间，而查询数据量巨大，引起数据库压力过大甚者宕机**

与缓存击穿不同的是，缓存击穿指一条热点数据在Redsi没有得到及时重建，缓存雪崩是一大批数据在Redis同时失效

- 解决方案


1. 缓存数据在过期时间设置随机，防止同一时间大量数据过期现象发生

2. 重建缓存加互斥锁，当线程拿到缓存发现缓存不存在就会尝试加锁，线程挣抢锁，拿到锁的线程就会进行查询数据库，然后重建缓存


> 关于缓存击穿和缓存雪崩的解决方案中，重建加互斥锁的理解：
>
> 当线程发现缓存过期，就尝试加锁，线程争抢锁，拿到锁的线程就进行数据库查询，然后重建缓存，争夺锁失败的线程，增加一个睡眠循环重试

### 1.3缓存一致性

#### 缓存一致性问题：

缓存，是持久化数据的冗余存储，但如果缓存加载了数据源的数据，但对应数据要发生改变，要怎么办？

缓存一致性大概有三个方向（以旁路模式为基础）：

1. 更新Mysql即可，不管Redsi，以过期时间兜底

2. 更新Mysql之后，操作Redsi

3. 异步将Mysql的更新同步到Redis


> 不能先更新redis后更新mysql，这种方式会带来数据丢失的可能，缓存的数据如果在更新到mysql之前发生了崩溃，就发生了数据丢失

#### 方向一：更新Mysql即可，不管Redsi，以过期时间兜底（缺点明显）

使用Redsi过期时间，mysql更新时，redis不做处理，等待缓存过期失效，再从mysql拉取缓存

但是这个方案不一致时间比较明显。

如果读请求非常频繁，且过期时间设置较长，则会产生很大脏数据

优点：

1. redis原生接口，开发成本低，易于实现

2. 管理成本低，出问题的概率低


不足：

- 完全依赖过期时间，时间太短容易造成缓存频繁失效，太长容易造成数据不一致


#### 方向二：更新Mysql之后，操作Redsi

不光通过key的过期时间兜底，还需要在更新mysql时，同时尝试操作redis（有两种操作方式：一是直接将结果写入Redis，二是先删除key等下次访问在加载回来）

优点：

1. 相对方案一，达成最终一致性的延迟更小

2. 实现成本较低，只是在方案一的基础上，增加了删除逻辑


缺点：

1. 如果更新mysql成功，删除redis失败，就退化到方案一

2. 在更新时候需要额外操作redis，带来了损耗


#### 方向三：异步将Mysql的更新同步到Redis

把我们搭建的消费服务作为mysql的一个slave，订阅mysql的binlog日志，解析日志内容，再更新到redis。此方案（阿里的[canal](https://github.com/alibaba/canal)组件）和业务完全解耦，redis的更新对业务放透明，可以减少心智成本

优点：

1. 和业务解耦，在更新mysql中，不需要做额外操作

2. 无时序性问题，可靠性强


缺点：

1. 引入了消息队列这种算比较中的组件，还要单独搭建一个同步服务，维护他们是非常大的成本

2. 同步服务如果压力比较大，或者崩溃了，那么较大时间内，redis中都是老数据


> 理解：这里的消费服务，指另起一个服务，通过订阅binlog日志，解析日志内容，再更新到redis，实现redis缓存一致。

![](https://rt5bap83jl.feishu.cn/space/api/box/stream/download/asynccode/?code=MDY1YzA4ZmIyNjU5ZTllZTA5NTJhM2VjOTAwYmQ2ZWVfTXAwbkJsY0w4MkNQQXQzVEE5QW1XU0FRbmxvR1h6d2dfVG9rZW46TUVSc2JZN1F2bzE5WXF4NTRuMGNhTFdqbnpmXzE3MjE4NDE0OTU6MTcyMTg0NTA5NV9WNA)

## 2.分布式锁（非常重要）

### 分布式锁是什么？

首先理解**锁，**什么是锁？锁可以理解为针对某项资源使用权限的管理，通常用来控制共享资源

而分布式锁，就是在分布式场景下的锁，比如多台不同机器上的进程，去竞争同一项

### 分布式锁有哪些特性？

- 互斥性：锁的目的是获取资源的使用权，只能让一个竞争者持有锁

- 安全性：避免锁因为异常永远不被释放。

- 对称性：同一个锁，加锁和解锁必须是同一个竞争者

- 可靠性：需要有一定程度的异常处理能力、容灾能力


### 分布式锁的常用实现方式？

分布式锁，一般依托第三方组件实现，而利用Redis实现则是工作中应用最多的一种

#### 简化版本

首先，搭建一个最简单的实现方式，直接用Redis的setnx命令

> Setnx key value 如果key不存在，则会将key设置为value，并返回1；如果key存在，不会有任何影响，返回0

基于这个特性，我们可以用setnx实现加锁目的：通过setnx加锁，加锁后其他服务无法加锁，用完之后，再通过delete解锁

![](https://rt5bap83jl.feishu.cn/space/api/box/stream/download/asynccode/?code=MDYyODg1ZDI0NGIzM2ViMDA1ZDM1NmVmZjMzMTQwNzBfRlh5MmVIamx6Wks4Sld5REFSUnVLT1Q0MTdmclhhWG5fVG9rZW46RW0wcWJUYW84b1hlc1d4eE55UmNUdFNMbm9mXzE3MjE4NDE0OTU6MTcyMTg0NTA5NV9WNA)

#### 支持过期时间

上面的版本存在一个问题：如果获取锁的服务挂掉了，那么锁就一直得不到释放，所以需要一个超时来兜底

Redis中有expire命令，用来设置一个key的超时时间，但是setnx和expire不具备原子性，如果setnx获取锁之后，服务挂掉，依旧是不行的

Redis推出了以下执行语句：**set key value nx ex seconds**

![](https://rt5bap83jl.feishu.cn/space/api/box/stream/download/asynccode/?code=ZWI1ZmFlN2JmN2I2ODNhMDRmMjNkOTExOGVjMmEwN2NfR2xLWW9JdEl1ZGprZkdZQ29MZWJ2NXR5eXFIZXV3eVFfVG9rZW46T29KaGJvUkI3bzByQU54d1ZYTWN0ZFBDbk1iXzE3MjE4NDE0OTU6MTcyMTg0NTA5NV9WNA)

以上，这个锁就能支持过期时间，基本可以使用

但是存在一个问题：服务A可能会释放掉服务B的锁的可能

#### 加上owner

分布式锁需要满足谁申请释放原则，不能释放别人的锁，也就是说，分布式锁是要有归属的

![](https://rt5bap83jl.feishu.cn/space/api/box/stream/download/asynccode/?code=MmM3ODRhNTQ2MTIxNGQ5NjBiZjY5ZmIxZjE3YTU5MGVfMTdRSkhzSVFkVVNZSzg3UnhoNk9TVkRnMlIwZUJsR2RfVG9rZW46S2VsN2JCcFFwb2xQbUJ4SFF5cWNuV1NNbjZiXzE3MjE4NDE0OTU6MTcyMTg0NTA5NV9WNA)

#### 引入Lua

加入owner后的版本还不算称得上是完善的，还不具备原子性

使用Redis的原子操作特性，——Lua

使用`Redis+Lua`，专门解决原子问题，有了Lua特性，Redis才真正在分布式锁，秒杀等场景有了可用性

![](https://rt5bap83jl.feishu.cn/space/api/box/stream/download/asynccode/?code=MjE2NjBlNDkzNTE0Y2VmMzM0ZDRmNGFhMzdkNGI0YjNfdmRuVHVwcm9xWUxtQjVjc0ppOEc0aFJiNE9vMU4zTlBfVG9rZW46RDNqMWJSUnNXb0xYb2l4YmFFN2NQcFRBbmpjXzE3MjE4NDE0OTU6MTcyMTg0NTA5NV9WNA)

到这里，分布式的前三个特性：对称性，安全性，互斥性就满足了

### 可靠性如何保证？

分布式锁的**可靠性，**针对一些异常场景，例如Redis挂掉、业务执行时间长，网络波动等等

#### 容灾考虑

前面的内容基本都是基于单机考虑，如果Redis挂掉，那锁就不能获取了

有两种方法：

- 主从容灾

- 多级部署


##### **主从容灾**

最简单的一种方式，就是为Redis配置从节点，当主节点挂了，用从节点顶包

但是主从切换，需要人工参与，会提高人力成本。不过Redis已经有成熟的解决方案，也就是**哨兵模式**，可以灵活自由切换

通过增加从节点的方式，虽然一定程度解决了单点的容灾问题，但由同步有时延，Slave可能会损失部分数据，分布式锁可能失效，这就会发生短暂的多机获取到执行权限

##### 多机部署

如果对一致性要求高，可以使用多机部署，比如Redis的RedLock，大概的思路就是多个机器（奇数），达到一半以上同意加锁才算加锁成功，这样可靠性会向ETCD靠近

### 可靠性研究

由于分布式系统中的三大困境（简称NPC），所以没有完全可靠的分布式锁

RedLock在NPC下的表现：

- N：Network Delay（网络延迟）当分布式锁获得返回包的时间过长，可能虽然加锁成功，但是延迟太高，导致锁过期。RedLock就利用了锁剩余时间需要减去请求时间

- P：Process Pause（进程暂停），比如发生GC，获取锁之后GC了，处于GC执行中，任何锁超时

- C：Clock Drift（时钟漂移）


## 3.Go实现redis分布式锁

分布式锁简单说就是**在分布式环境下不同实例之间抢一把锁**

> 分布式锁的难点基本上跟**网络**有关

redis实现一个分布式锁的起点，就是利用setnx命令，确保**排他设置一个键值对**

[极客时间训练营-让优秀的人一起学习](https://u.geekbang.org/lesson/492?article=615473)

## 事务