---
title:  "[redis] Base理论"
summary: Redis的基本概念及其应用场景，并解释了BASE理论
subtitle: "理解BASE理论，是CAP中一致性的妥协"
series: ["database"]
tags:  ["redis"]
date:  "2024-10-25"
categories: ["redis"]
---

## 一、什么是redis？

- redis是一个内存数据结构储存，KV储存
- 常用于缓存、消息中转、数据流引擎、分布式锁
- 支持的数据结构有：字符串、散列、列表、集合、带范围查询的排序集合、位图、超日志、地理空间索引和流

(strings, hashes, lists, sets, sorted sets with range queries, bitmaps, hyperloglogs, geospatial indexes, and streams)

- redis内置了复制、Lua脚本、LRU驱逐、事务和不同级别的磁盘持久化


> [Try Redis](https://try.redis.io/) 官方redis在线操作平台



## 二、Base理论

Base理论是CAP中一致性的妥协，不追求强一致性，允许数据在一段时间内不一致，但是最终达到一致状态

> [分布式系统的CAP定理与BASE理论](https://rt5bap83jl.feishu.cn/docx/XXiHdxRVRokY7vxCqVccZ9PlnVe)