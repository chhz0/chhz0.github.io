---
title: "[git] git-commit-message 规范"
subtitle: 符合Angular规范的Commit Message
date: "2024-09-28"
tags: ["git"]
categories: ["git"]
---

# 符合Angular规范的Commit Message

```text
<type>[(optional scope)]: <description>
// 空行
[optional body]
// 空行
[optional footers]
```
分为了Header、Body、footer三个部分

## Header
Header部分只有一行`<type>[(optional scope)]: <description>`，其中type必选，其它可选

type-->归为两类：
- Development(项目管理类变更，不影响用户和生产环境的代码)
- Production(影响用户和生产环境的代码)

| 类型     | 类别        | 说明                                                         |
| -------- | ----------- | ------------------------------------------------------------ |
| feat     | Production  | 新增功能                                                     |
| fix      | Production  | 修复缺陷                                                     |
| perf     | Production  | 提高代码性能的变更                                           |
| style    | Development | 代码格式类的变更，例如使用gofmt格式化代码                    |
| refactor | Production  | 其他代码类的变更，例如 简化代码、重命名变量、删除冗余代码等等 |
| test     | Development | 新增测试用例或更新现有的测试用例                             |
| ci       | Development | 持续基础和部署相关的改动，例如修改Jenkins、GitLab CI等Ci配置文件或者更新系统单元文件 |
| docs     | Development | 文档类的更新，包括修改用户文档、开发文档                     |
| chore    | Development | 其他类型，例如构建流程、依赖管理或者复制工具的变动           |

scope-->不设置太具体的值，说明commit的影响范围
description-->对commit的简短描述，以动词开头

## Body
Body对Commit Message的高度概况，方便查看具体做了什么变更

## Footer
Footer部分不是必选，可根据需要选择，主要用来说什么本次commit导致的后果，通常用来说明不兼容的改动或者关闭的issue
```text
BREAKING CHANGE: <breaking change summary>
// 空行
<breaking change description + migration instructions>
// 空行
// 空行
Fixes(Closes) #<issue number>
```

## Revert Commit
特殊的Commit Message。还原了先前的commit，则以`revert`开头，后面跟还原的commit的Header，
在Body必须写`This reverts commit <hash>`，其中hash为要还原的commit的SHA标识

> 使用`git commit -a`进入交互界面的Commit Message


--------
# git rebase
git rebase的最大作用是重写历史

使用`git rebase -i <commit ID>`使用git rebase命令  修改某次 commit 的 message

| 命令       | 目的                                   |
|----------|--------------------------------------|
| p,pick   | 不对该commit做任何处理                       |
| r,reword | 保留该commit，但是修改提交信息                   |
| e,edit   | 保留该commit，但是rebase是会暂停，允许你修改这个commit |
| s,squash | 保留该commit，但是将当前commit与上一个commit合并    |
| f,fixup  | 与squash相同，但不会保存当前commit的提交信息         |
| x,exec   | 执行其他shell命令                          |
| d,drop   | 删除该commit                            |

## git commit -amend
git commit –amend：修改最近一次 commit 的 message