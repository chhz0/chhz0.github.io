---
date: '2024-11-19T21:13:26+08:00'
draft: true
title: '[IAM] 身份认证和授权系统'
description: 'IAM系统是一个Web服务，用于统一用户认证和授权，支持基于角色的访问控制。'
tags: ['golang', "IAM"]
categories: ['实战项目']
---

# IAM 系统

## 组件
核心组件：
- iam-api-server: 认证和授权服务
- iam-authz-server: 授权服务
- iam-pump: 数据清洗服务
- iam-watcher: 分布式作业服务
- iam-sdk-go: SDK
- iamctl: 命令行工具

旁路组件：
- iam-app: 应用服务
- iam-webconsole: Web控制台
- iam-operating-system: 运营系统
- iam-loadbalancer: 负载均衡器

## 数据库
- Redis: 缓存数据库，缓存iam-authz-server的授权日志
- MySQL: 持久化存储用户、密钥和授权策略信息
- MongoDB: 持久化授权日志


IAM 资源授权流程

1. 用户注册并登录
2. 创建密钥对
3. 创建授权策略
4. 第三方访问IAM提供的授权接口

## docker
 docker run --name iam-mdb -v docker_iam_mdb_data_1:/var/lib/mysql -p 13306:3306 -e MYSQL_ROOT_PA
SSWORD=rootpwd -e MYSQL_USER=CHlluanma -e MYSQL_PASSWORD=iampwd -d mariadb