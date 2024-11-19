---
title:  "[redis] redis 对象"
subtitle: "学习redis中的对象: string list hash set zset ..."
tags:  ["redis"]
date:  "2024-10-26"
categories: ["redis"]
---

## 三、对象

### Redis Object 是什么？

redis是key-value存储，key-value在redis中被抽象为对象(Object)，key只能是String对象，value支持丰富的对象类型{String, List, Set, Hash, Sorted Set, Stream...}

#### Object在内存中的样子

```C
#define LRU_BITS 24

typedef struct reidsObject {
    unsigned type:4;
    unsigned encoding:4;
    unsigned lru:LRU_BITS;

    int refcount;
    void *ptr;
} robj;
```

- Type: 查看redis对象
- Encoding: 表明使用哪种底层编码
- Lru: 记录对象访问信息，用于内存淘汰
- Refcount: 引用计数，用来描述有多少指针，指向该对象
- Ptr: 内容指针，指向实际内容

#### 对象与数据结果

实际操作的对象有6个Redis对象，他们的底层依赖一些数据对象，包括字符串、跳表、哈希表、压缩列表、双端列表等

### 1.String

#### String是什么

String是字符串，是Redis中最基本的数据对象，最大为512MB，可以通过配置项**proto-max-bulk-len**修改它

String可以存储各种类型的字符串（包括二进制文件）

#### 适用场景

使用场景：一般用来存放**字节数据**、**文本数据**、**序列化****后的对象数据**

例子：
1. 缓存场景：Value存Json字符串等信息
2. 计数场景：因为Redis处理命令是单线程，所以执行命令的过程是原子的，因此String数据类型适合计数场景

#### 在redis中怎么使用：

常用操作：创建、查询、更新、删除

- 创建 --> set, setnx
    - **SET** key value # 设置一个key值为特定的value
	      set命令扩展参数：EX（键过期时间秒）、PX（键过期时间毫秒）、NX（只有键不存在时才对键进行操作，基本替代下面的SETNX操作）、XX（键存在时才对键进行操作）
    - **SETNX** key value # 用于在指定的**key不存在**时，为key设置指定的值
- 查询 --> get, mget

    - **Get** key # 查询某个key，存在就返回对应的value，不存在返回nil

    - **Mget** key [key ...] # 一次查询多个key，如果某个key不存在，对应位置返回nil

- 更新 --> set

    - 见上面的set

- 删除 --> del

    - **DEL** key [key ...] # 删除对象，返回值为删除成功了几行


#### 底层实现（很重要）

String有三种编码方式：**INT****、EMBSTR、****RAW**

- String对象编码

    - INT: 存放整形，可以用long表示的整数

    - EMBSTR: 如果字符串**小于等于(<=)**阈值字节(redis > 3.2 ? 44 : 39)，使用EMBSTR编码

    - RAW: 字符串**大于(>)**阈值字节，使用RAW编码


> 关于阈值字节大小，在源码中使用**OBJ_ENCODING_EMBSTR_SIZE_LIMIT**表示
>
> 3.2版本前是39字节，3.2版本之后是44字节

EMBSTR和RAW都是由redisObject和SDS两个结果组成，两者差异在于EMBSTR下redisObject和SDS是连续的内存，RAW编码下redisObject和SDS的内存是分开的

EMBSTR的优缺点：

1. 优点：一次性分配内存，redisObject和SDS两个结构一次性分配内存

2. 缺点：重新分配空间时，整体需要重新再分配

3. EMBSTR设计为只读，任何写操作之后EMBSTR都会变成RAW


编码转化的可能：

INT -> RAW: 当内存不再是整形，或者大小超过了long

EMBSTR -> RAW: 任何写操作之后EMBSTR都会变成RAW

- **SDS**(Simple Synamic String)，简单动态字符串，是redis内部作为基石的字符串封装（很重要）


SDS是redis封装字符串结构，用以**解决字符串追加和长度计算操作来带的性能瓶颈**问题

redis中SDS分为sdshdr8、sdshdr16、sdshdr32、sdshdr64，字段属性一致，区别再对应不同大小的字符串

```C
struct __attribute__((__packed__)) sdshdr8 {
    uint8_t len;   // 使用了多少内部
    uint8_t alloc; // 分配了多少内存
    unsigned char flags; // 标记是什么分类 例如： #define SDS_TYPE_8 1
    char buf[];
}
```

从上面的结构可以看出SDS是怎么解决问题的：

1. 增加len字段，快速返回长度

2. 增加空余空间(alloc - len)，为后续追加数据留余地

3. 不要以'\0'作为判断标准，二进制安全


SDS预留空间大小的规则：alloc = min(len, 1M) + len：

len小于1M的情况下，alloc=2*len, 预留len大小的空间

len大于1M的情况下，alloc=1M+lne, 预留1M大小的空间



### 2.List

#### List是什么

Redis List是一组了解起来的字符串**集合**

#### 适用场景

List作为一个列表存储，属于比较底层的数据结构，可以实验的场景非常多，比如存储一批任务数据，存储一批消息

#### 在Redis中怎么使用

常用操作：创建、查询、更新、删除

- 创建 --> LPUSH, RPUSH

    - **LPUSH** key value [value ...] 从头部增加元素，返回List中元素总数

    - **RPUSH** key value [value ...] 从尾部增加元素，返回List中元素总数

- 查询 --> LLEN, LRANGE

    - **LLEN** 查看List的长度，即List中元素的总数

    - **LRANGE** key start stop 查看start到stop为角标的元素

- 更新 --> LPUSH, RPUSH, LPOP, RPOP, LREM

    - **LPOP** key 移除并获取列表的第一个元素

    - **RPOP** key 移除并获取列表的第一个元素

    - **LREM** key count value 移除值等于value的元素

            count = 0 ，则移除所有等于value的元素；

            count > 0 ，则从左到右开始移除count个value元素；

            Count < 0，则从右往左移除count个元素

- 删除 --> DEL, UNLINK

    - **DEL** key [key ...] 删除对象，返回值为删除成功了几个键

    - **UNLIKN** key [key ...] 删除对象，返回值为删除成功了几个键


> del命令与unlink命令均为删除对象，**不同**的是
>
> del命令是**同步**删除目录，会阻塞客户端，直到删除完成；
>
> unlink命令是**异步**删除命令，只是取消key在键空间的关联，让其不在能查到，删除是异步进行，所以不会阻塞客户端

#### 底层实现（*）

List对象有两种编码方式（在版本3.2之前）：ZIPLIST、LINKEDLIST

满足以下条件时，使用ZIPLIST编码：

1. 列表对象保存的所有字符串对象长度都**小于64字节**

2. 列表对象元素个数少于512个，这是LIST的限制，不是ZIPLIST的限制


ZIPLIST底层用**压缩列表**实现，ZIPLIST内存排序很紧凑，可以有效节省内存空间

![](https://rt5bap83jl.feishu.cn/space/api/box/stream/download/asynccode/?code=NWMxZjQwZGYwMDAzMDQzMzNiOTQwZGE2NWNiOWY4ODBfZUZ3a1p6TWZWVUFTQ0FMd2dpamd5SGRiZzdCVkxSSldfVG9rZW46UlkzNmJTNUFLb0JNZWJ4VW9YRGNRckkzbnFlXzE3MjE4NDEzNjY6MTcyMTg0NDk2Nl9WNA)



> 压缩列表的数据是紧凑的

不满足ZIPLIST编码条件时，则使用**LINKEDLIST编码**

![](https://rt5bap83jl.feishu.cn/space/api/box/stream/download/asynccode/?code=OWIwMWM5N2NiMDM3Zjk2NjU0MGU4ZTM5NjliZDI5YzJfSldnTkJVQWZvbzVOaXdreUhybk5QbHZqVDNlTHdkNjdfVG9rZW46VURURGJBd1hKb3gwNlF4dEExMmNQeE9nbllmXzE3MjE4NDEzNjY6MTcyMTg0NDk2Nl9WNA)

```C
typedef struct list {
    listNode *head;
    listNode *tail;
    void *(*dup)(void *ptr);
    void (*free)(void *ptr);
    int (*match)(void *ptr, void *key);
    unsigned long len;
} list;
```

使用LINKEDLIST编码，是几个String对象的链接结构，以链表的形式连接，删除更加灵活但是在内存上不如ZIPLIST紧凑，所以只有在**列表个数或节点长度比较大**的时候，才会使用LINKEDLIST编码，LINKEDLIST编码以牺牲内存换取了更加快处理的性能

> 分析：
>
> ZIPLIST是为了数据较少时节约内存
>
> LINKEDLIST是为了数据多时提高更新效率，ZIPLIST数据稍多是插入数据会导致很多内存复制

- **QUICKLIST** 横空出世


3.2版本之后引入了**QUICKLIST，**QUICKLIST其实就是ZIPLIST和LINKEDLIST的结合体（LINKEDLIST原来单个节点只能存放一个数据，现在单个节点存放的是一个ZIPLIST）

![](https://rt5bap83jl.feishu.cn/space/api/box/stream/download/asynccode/?code=MWI3MjEzYzliMDk5NzUwZjRiMzU0MmU5NmIwMDcyOTNfb1hGWGt4OGpoMkZxM2tMNW1ENklQNVd3emVNYzdrM1hfVG9rZW46UGZWY2JXUFNab0FoR0l4SnE5Y2NuampKblNjXzE3MjE4NDEzNjY6MTcyMTg0NDk2Nl9WNA)

当数据较少时，QUICKLIST的节点就只有一个，相当于一个ZIPLIST

当数据很多的时候，则同时利用ZIPLIST和LINKEDLIST的优势

#### ZIPLIST优化

ZIPLIST存在一个连锁更新问题，在Redis 7.0之后，使用LISTPACK（也称为紧凑列表）的编码模式取代了ZIPLIST，而他们其实本质都是一种压缩的列表，所以可以统一叫做压缩列表



### 2.1底层数据结构--压缩列表

压缩列表，就是排列紧凑的列表，在Redis中有两个编码方式，一种是ZIPLIST，另一种是LISTPACK（于redis 5.0引入知道redis 7.0完全替代ZIPLIST）

#### 压缩列表解决什么问题？

压缩列表是List的底层数据结构，压缩列表主要用做**为底层数据结构提供紧凑型的数据存储方式，能节约****内存**（节省列表指针的开销），小数据量的时候遍历访问性能好（连续+缓存命中率友好）

#### ZIPLIST整体结构

虽然有LISTPACK，但是实际面试中还是ZIPLIST比较多

```C
// redis代码注释，描述了ZIPLIST的结构

 * <zlbytes> <zltail> <zllen> <entry> <entry> ... <entry> <zlend>
```

各字段定义：

- zlbytes: 表示该ZIPLIST一共占了多少字节，这个数字是包含zlbytes本身占据的字节的

- zltail: ZIPLIST尾巴节点，相对于ZIPLIST的开头，偏移的字节数

- zllen: 表示有多少个数据节点

- entry: 表示压缩列表的数据节点

- zlend: 一个特殊的entry节点，表示ZIPLIST的结束


#### ZIPLIST节点结构<entrys>

定义如下：

```C
<prevlen> <encoding> <entry-data>
```

各字段含义：

- Prevlen: 表示上一个节点的数据长度。通过该节点可以定位上一个节点的起始地址，(p - prevlen)可以跳到前一个节点的开头位置，实现往前操作，即压缩列表可以从后往前遍历


一个entry的大小，小于254字节，那么prevlen熟悉需要1字节长的空间来保存这个长度，**255是特殊字符，被zlend使用了**

当entry的大小大于等于254字节，那么prevlen属性需要用5字节长的空间来保持这个长度值，注意**5个字节中第一字节为11111110，也就是254**，标志这是个5字节的prelen信息，剩下4个字节来表示大小

- Encoding: 编码类型，包含了一个entry的长度信息，可用于正向遍历

- Entry-data: 实际的数据


#### encoding说明

encoding字段是一个整形数据，其二进制编码由内容数据(entry-data)的类型和内容数据(entry-data)的字节长度两部分组成，根据内容类型有如下几种情况

...

|   |   |   |
|---|---|---|
|类型|区分|补充|
|String|前几位标识类型，后几位标识长度||
|int|整体1字节编码，只标识了类型，没有大小|因为int的具体类型自带大小，比如int32，就是32位，4字节大小，不需要encoding特别标识|

#### ZIPLIST查询数据

两个关键操作：查询ZIPLIST的数据总量，查询指定数据的节点

- **查询ZIPLIST的数据总量**


ZIPLIST的header定义了记录节点数量的字段zllen，所以**通常**是在O(1)时间复杂度直接返回，为什么是通常？因为zllen是2个字节，当zllen大于65534时，zllen就存不下了，此时真实的节点数量需要遍历得来。

之所以zllen是2个字节，原因是redis中应用ZIPLIST是为了节点个数少的场景，所以将zllen设计得比较小，节约内存空间

- **查询指定数据的节点**


在ZIPLIST中查询指定数据的节点，需要遍历整个压缩列表，平均时间复杂度为O(N)

#### ZIPLIST更新数据

ZIPLIST的更新就是增加、删除数据，ZIPLIST提供头尾增减的能力，但是操作平均时间复杂度O(N)，因为在头部增加一个节点会导致后面节点都往后移动，所以更新平均时间复杂度O(N)

更新操作可能带来连锁更新。连锁更新是指节点后移发生不止一次，而是多次（一般）

#### LISTPACK优化

LISTPACK是为了解决ZIPLIST最大的痛点——连锁更新

> ZIPLIST需要支持LIST，LIST是一种双端访问的结构，所以需要能从后往前遍历
>
> ZIPLIST的数据节点：<prevlen> <encoding> <entry-data>
>
> 其中，prevlen表示上个节点的数据长度，通过这个字段可以定位上一个节点的数据
>
> **连锁更新的问题，就是因为prevlen导致的**

LISTPACK以一种不记录prevlen，并且还能找到上一个节点的起始位置的节点结构，解决了这一问题

```C
<encoding-type><element-data><element-tot-len>
```

- encoding-type是编码类型，element-data是数据内容，element-tot-len存储整个节点除了它自身之外的长度(*)

- element-tot-len所占用的每个字节的**第一个bit**用于标识是否结束，剩下7个bit来存储数据大小

    - 0 是结束

    - 1 是开始


#### 总结

- 重点理解压缩列表是节约内存的一种数据结构，它采取了将数据紧密排列的形式来压缩空间

- 理解ZIPLIST的基本操作--查询&&更新

- 重点理解ZIPLIST节约内存的思路




### 3.Set

#### Set是什么

Redis的Set是一个不重复，无序的字符串集合（而外补充，如果是INTSET编码的时候其实是有序的，不过一般不应该依赖这个，整体上还是当成无序来用比较好）

#### 适用场景

适用于无序集合场景，例如某用户关注了哪些公众号，这些信息放进一个集合，Set还提供了查交集，并集的功能，可以很方便实现共同关注的能力

#### 常用操作

Set的基本操作有：创建，查询，更新，删除

- 创建：SADD

    - **SADD** key member [member ...] 添加元素，返回值为成功添加了几个元素

- 查询：SISMEMBR, SCARD, SMEMBERS, SSCAN, SINTER, SUNION, SDIFF

    - **SISMEMBER** key member 查询元素是否存在

    - **SCARD** key 查询集合元素个数

    - **SMEMBERS** key 查看集合的所有元素

    - **SSCAN** key cursor[MATCH pattern][COUNT count] 查看集合元素，可以理解为指定游标进行查询，可以指定个数，默认为10

    - **SINTER** key [key ...] 返回在第一个集合，同时在后面**所有集合都存在**元素

    - **SUNION** key [key ...] 返回所有集合的并集，集合个数大于等于2

    - **SDIFF** key [key ...] 返回第一个集合有，且后续集合中不存在的元素，结合个数大于等于2，注意

- 更新：SADD, SREM

    - **SADD -- >** 参考上文

    - **SREM** key member [member ...] 删除元素，返回值为成功删除几个元素

- 删除：DEL

    - DEL key 删除元素


#### 底层编码

Set的底层编码是Set对象编码，Set对象编码：**INTSET，HASHTABLE**

如果集群元素都是整数，且元素数量不超过52个，可以用INTSET编码，结构如下

![](https://rt5bap83jl.feishu.cn/space/api/box/stream/download/asynccode/?code=ZGZlZTlmOGVjNWQ5NTViZmU1OWEwNDI2NWYyNjk3NzZfSXlXblZ0NXJxV3JtMWxBRkZxWmhKMFM5VFN1ZXhQSW9fVG9rZW46THNCMGJpcFV2b2ZzQk54RHpGdWNLQmp6bnRjXzE3MjE4NDEzNjY6MTcyMTg0NDk2Nl9WNA)

可以看到INTSET排列比较紧凑，内存占用少，但是查询的时候需要二分查找

当不满足INTSET条件时，需要HASHTABLE，结构如下

![](https://rt5bap83jl.feishu.cn/space/api/box/stream/download/asynccode/?code=NzE3NzJiNGJmMDdlMzFiMjFkMWViODM4MGY5NThlNDhfRWEzTG45N1NtZm5qZldPQjB6MGk2b21rSE16OUpPcFpfVG9rZW46RDR5b2JtOWZEb1IyaHB4VkRlM2NHbUx4blpjXzE3MjE4NDEzNjY6MTcyMTg0NDk2Nl9WNA)

HASHTABLE查询一个元素的性能很高，能O(1)时间就能找到一个元素是否存在



### 4.Hash

#### Hash是什么

Redis Hash是一个field、value都为String的哈希表，存储在Redis内存中

redis中每个hash可以存储（ 2^32-1 ）键值对

#### 使用场景

适用于O(1)时间字典查找某个field对应数据的场景，例如任务信息的配置，可以任务类型为field，任务配置参数为value

#### 在redis中怎么使用

常见操作：创建，查询，更新，删除

- 创建：HSET, HSETNX

    - **HSET** key field value 为集合对于field设置value，可以一次设置多个field-value

    - **HSETNX** key field value 如果field不存在，则为集合对应field设置value数据

- 查询：HGETALL, HGET, HLEN, HSCAN

    - **HGETALL** key 查找全部数据

    - **HGET** key field 查找某个key（field）

    - **HLEN** key 查找Hash中元素总数

    - **HSCAN** key cursor [MATCH pattern] [COUNT count] 从指定位置查询一定数量的数据，这里注意如果是小数据量下，处于ZIPLIST时，COUNT不管填多少，都是返回全部，因为ZIPLIST本身就用于小集合，没必要切分几段返回

- 更新：HSET, HSETNX, HDEL

    - **HDEL** key field [field ...] 删除指定field，可以一次删除多个

- 删除：DEL

    - **DEL** key [key ...] 删除Hash对象


#### 底层原理

Hash底层有两种编码格式，一个是压缩列表（ZIPLIST），一个是HASHTABLE，满足以下两个条件，用压缩列表：

1. Hash对象保存的所有值和键的长度都小于64字节

2. Hash对象元素个数少于512个


当Hash的底层编码为ZIPLIST时，即数据量较少时将数据紧凑排列，对应到Hash，就是**将field-value当作entry放入ZIPLIST**

如果Hash的底层编码为HASHTABLE时，与上面的Set（无序列表）使用HASHTABLE，区别在于在Set中Value始终为null，但是在HSet中，是有对应的值

### 4.1底层结构--HASHTABLE

#### HASHTABLE概述

通过HASHTABLE可以使用O(1)时间复杂度能够快速找到key对应的value，简单理解，HASHTABLE是一个目录，可以帮助我们快速找到需要内容

#### HASHTABLE结构

```C
typedef struct dictht {
    dictEntry **table;
    unsigned long size;
    unsigned long sizemask;
    unsigned long used;
} dictht;
```

最外层封装一个**dictht**结构，字段含义如下：

- Table: 指向实际hash存储。存储可以看做一个数组

- Size: 哈希表大小，实际就是dictEntry有多少元素空间

- Sizemask: 哈希表大小的掩码表示，总是等于size-1. 这个属性和哈希值一起决定一个键应该放到table数组的那个索引上面，规则Index=hash&sizemask.

- Used: 表示已经使用的节点数量。通过这个字段可以查询目前HASHTABLE元素总量


![](https://rt5bap83jl.feishu.cn/space/api/box/stream/download/asynccode/?code=YmIyOWI5ZDM0ZjJkNmUxNTdiZmQ5NzI4MjE3MzM0OGVfYTFuOTdRZ3gwUzhGNkFtWnFuYkl0bFZ5emx6aVlLN1JfVG9rZW46S2JZcmI4S0I0b01wTDR4RUV6cWNPNUR5blFmXzE3MjE4NDEzNjY6MTcyMTg0NDk2Nl9WNA)

#### Hash表渐进式扩容

渐进式扩容就是一点一点扩大HASHTABLE的容量，默认值为4（#define DICT_HT_INTTIAL_SIZE 4）

为了实现渐进式扩容，Redis没有直接把dictht暴露给上层，而是再封装了一层

```C
typedef struct dict {
    dictType *type;
    void *privdata;
    dictht ht[2];
    long rehashidx;
    unsigned long iterators;
} dict;
```

dict结构里面，包含了2个dictht结构，也就是2个HASHTABLE结构。

dictEntry是链表结构，用拉链法解决Hash冲突，用的是头插法

实际上，平时使用的时候就是一个HASHTABLE，在触发扩容之后，就会有两个HASHTABLE同时使用，详细过程如下：

当向字典添加元素时，需要扩容时会进行rehash

Rehash流程分以下三步：

1. 为新Hash表ht[1]分配空间，新表大小为第一个大于等于原表ht[0]的2倍used的2次幂。例如，原表used=500，2*used=1000，第一个大于1000的2次幂为1024，因此新表的大小为1024. 此时，字典同时持有ht[0]和ht[1]两个哈希表，字典的偏移索引rehashidx从静默状态-1，设置为0，表示Rehash正式开始工作。

2. 迁移ht[0]数据到ht[1]**在Rehash进行期间**，每次对字典执行增删改查操作，程序会顺带迁移当前rehashidx在ht[0]上的对应数据，并更新**偏移索引(rehashidx)**。

3. 随着字典操作的不断执行，最终在某个节点，ht[0]的所有键值对会被Rehash到ht[1]，此时再将ht[1]和ht[0]两个指针对象互换，同时把偏移索引的值设置为-1，表示Rehash操作已经完成。


小总结：渐进式扩容的核心是操作时顺带迁移

#### 扩容时机

redis提出一个负载因子的概念，负载因子表示目前Redia HASHTABLE的负载情况

用k表示负载因子：k=ht[0].used/ht[0].size，也就是使用空间和总空间大小的比例，redis会根据负载因子的情况来扩容：

1. 负载因子k大于1时，说明此时空间非常紧张，新数据在链表上叠加，越来越多的数据导致查询无法在O(1)时间复杂度找到，还要遍历链表，如果此时服务器没有执行BGSAVE或BGREWRITEAOF两个命令，就会发生扩容。

2. 负载因子k大于5时，说明HASHTABLE已经不堪重负，此时即使有复制命令在，也要进行扩容


#### 缩容

当有了多余的空间，如果不释放，就会导致多余的空间被浪费

缩容过程和扩容是相似的，也是渐进式缩容，同样缩容时机也是用负载因子来控制的

当负载因子小于0.1，此时进行缩容，新表的大小为第一个大于等于used的2次幂

使用BGSAVE或BGREWRITEAOF两个复制命令，缩容也会受影响，不会进行



### 5. ZSet

#### ZSet是什么

ZSet是有序集合，也叫做Sorted Set，是一组按照关联积分有序的字符串集合，这个分数是抽象概念，任何指标都可以抽象为粉丝，以满足不同场景

积分相同的情况下，按字典序排序

#### 适用场景

用于需要排序集合的场景，（例如经典的游戏排行榜）

#### 常用操作

- 创建：ZADD

    - ZADD key score member [score member] 向Sorted Set增加数据，如果key已经存在的Key，则更新对应的数据

        - 扩展参数：XX, NX, LT, GT

- 查询：ZRANGE, ZCOUNT, ZRANK, ZCARD, ZSCORE

    - ZCARD key 查看ZSet中的成员

    - ZRANGE key start stop [WITHSCORES] 查询从start到stop范围的ZSet数据，WITHSCORES选填，不写输出里只有key，没有score值

    - ZREVRANGE key start stop [WITHSCORES] 即reverse range，从大到小遍历，WITHSCORES选项，不写不会输出score

    - ZCOUNT key min max 计算min-max积分范围的成员

    - ZRANK key member 查看ZSet中member的排名索引，索引从0开始，所以排名是第一，索引就是0

    - ZSCORE key member 查询ZSet成员的分数

- 更新：ZADD, ZREM

    - ZREM key member [member ...] 删除ZSet中的元素

- 删除：DEL, UNLINK


#### 底层实现

ZSet底层编码有两种，一个是ZIPLIST，另一种是SKIPLIST+HASHTABLE

在ZSet中，ZIPLIST也是用于数据量比较小的时候节省内存，结构如下

![](https://rt5bap83jl.feishu.cn/space/api/box/stream/download/asynccode/?code=YmI0OTcwZjczM2IzOTFiNWM3YjFlZGE5YTI3ZWM2M2RfUXVWUEFzSThqN0lEaFp3S3BIck5kdmVWbzBQTHdPbzRfVG9rZW46VmpRbGJZWVo5b0RVMjh4OXEzamNJVnFabmxjXzE3MjE4NDEzNjY6MTcyMTg0NDk2Nl9WNA)

如果满足如下规则，ZSet就用ZIPLIST编码：

1. 列表对象保存的所有字符串对象长度都小于64字节

2. 列表对象元素个数少于128个


当上面条件任何一条不满足，编码就用SKIPLIST+HASHTABLE

SKIPLIST是一种可以快速查找的多级链表结构，通过SKIPLIST可以快速定位到数据所在，它的排名操作、范围查询性能都很高



### 6.底层数据结构--跳表

#### 跳表是什么

跳表是Redis有序集合ZSet底层的数据结构

redis中跳表的两处应用：1. 实现有序集合键、2. 在集群节点中作为内部数据结构

从本质上看是**链表**，这种结构虽然简单清晰，但是查询某个节点的效率比较低，而在有序集合场景，无论是查找还是添加删除元素，我们是需要快速通过score定位到具体位置，如果是链表的话时间复杂度是O(N)

为了提高查找的性能，Redis引入跳表，跳表在链表的基础上，给链表增加了多级的索引，通过索引可以一次实现多个节点的跳跃，提高性能

#### 跳表的结构

> 标准的跳表有如下限制：
>
> 1. score值不能重复；
>
> 2. 只有向前指针，没有回退指针
>

**在Redis中，使用的不是标准的跳表，其对跳表做了一些优化，包括score可以重复，增加回退指针**

#### Redis的跳表实现

redis中的跳表，score可以重复，并且每个节点多一个回退指针

![](https://rt5bap83jl.feishu.cn/space/api/box/stream/download/asynccode/?code=MmViMjNmZjdlYTcyN2VkN2RkZDk3NzQ3NTQ4Nzc2ZmVfQWtqRExDS0FvNk1LNGZMUzh3UmpoUk14OHJ4eXlpMk9fVG9rZW46VFA5aGJzbXJXb3dQcEh4TWFkbWNCS2t5bjNDXzE3MjE4NDEzNjY6MTcyMTg0NDk2Nl9WNA)

结合源码，Redis跳表单个节点的定义：

```C
typedef struct zskiplistNode {
    sds ele;
    double score;
    struct zskiplistNode *backward;
    struct zskiplistLevel {
        struct zskiplistNode *forward;
        unsigned long span;
    } level[];
} zskiplistNode;
```

字段的定义：

- Ele: SDS结构，用来存储数据

- Score: 节点的分数，浮点型数据

- Backward: 指向上一个节点的回退指针，支持从表尾向表头遍历，也就是ZREVRANGE这个命令

- level: 是个zskiplistLevel结构体数组，包含两个字段，一个是forward，指向该层下个能跳到的节点，span记录距离下个节点的步数，数组结构表示每个节点可能是多层结构


#### 跳表关键的细节

##### Redis跳表单个节点有几层？

层次的决定，需要比较随机，才能在各个场景表现出较平均的性能，这里Redis使用概率均衡的思路来确定插入节点的层数：

Redis跳表决定每一个节点，是否能增加一层的概率为25%，而最大层数限制在Redis 5.0是64层，在Redis 7.0是32层

##### Redis跳表的性能优化了多少？

平均时间复杂度为O(logn)，跳表的最坏平均时间复杂度是O(N)，当然实际的生产过程中，体现出来的基本是跳表的平均时间复杂度



### 7.Stream(不重要，基本不考)



[Stream（不重要，基本不考）](https://ls8sck0zrg.feishu.cn/wiki/wikcnD4ZGdQ1RJ2E0t6iIVoZJqT)



### 8.其他操作对象（不重要，基本不考）



[其它操作对象（不重要，基本不考）](https://ls8sck0zrg.feishu.cn/wiki/wikcnNZKYofaOkDNhtQd3x1ZoQe)



> 各对象对应的编码

暂时无法在飞书文档外展示此内容



### 9.对象过期时间

#### 过期时间是什么

redis的过期时间是给一个key，指定一个时间点，等达到这个时间，数据就会被认为是过期时间，可以redis进行回收

#### 为什么要过期时间

如果不需要常驻的数据，设置过期时间，可以有效地节约内存。另外，有些场景功能也需要过期时间支持，比如缓存、分布式锁

#### 怎么设置过期时间

如果是简单字符串对象，使用以下语法：

SET key value EX seconds；

SET key value PX milliseconds；设置毫秒

TTL key；查看还有多少时间过期

**设置过期时间之后会有个字典，专门记录Key和过期时间的关系**

#### 键过期多少时间后多久会删除

过期之后的键实际上不是立即删除的，一般过期键清除策略有三种：

1. 定时删除

2. 定期删除

3. 惰性删除


##### 定时删除

是在设置键的过期时间的时候，创建一个定时器，让定时器在键过期时间立即执行对键删除操作，定时删除对内存友好，但是对CPU不友好，如果某个时间段比较多的Key过期，可能会影响命令处理性能

##### 惰性删除

是指使用的时候，发现key过期了，此时再进行删除，这个策略的思路是对应用而言，只要不访问，过期不过期业务都无所谓，但是这样的代价是如果某些key一直不访问，那些本该过期的key变成了常驻的key。这种策略对CPU最友好，但是对内存不太友好

##### 定期删除

每过一段时间，程序就对数据库进行一次检查，每次删除一部分过期键，这属于一种渐进式兜底策略



Redis过期键采用的是惰性删除+定期删除二者结合的方式进行删除

惰性删除：Redis每次访问Key前都会进行检查，如已过期就删除

定期删除：

1. 定期删除的频率


这个决定于Redis周期任务的执行频率，周期任务里面会关闭过期客户端、删除过期key的一系列任务，可以用INFO查看周期任务

:: hz:10

hz频率默认是10，也就是1s 10次触发周期任务

2. 每次删除的数量


每次检查的数量是写死在代码里面的，每次20个，但是会有一个循环会检查过期key数量占比，大于25%，则再抽查20个来检查

Redis为了保证定期不会出现循环过度，导致线程卡死，为此增加了了定期删除循环流程的时间上限，默认不超过25ms

```C
#define ACTIVE_EXPIRE_CYCLE_LOOKUPS_PER_LOOP 20
```