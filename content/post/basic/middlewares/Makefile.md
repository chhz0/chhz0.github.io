--- 
title:  "[makefile] makefile学习笔记"
subtitle: "学习如何编写makefile"
tags:  ["makefile"]
date:  "2024-10-31"
---

learn form [(陈皓) 跟我一起写 Makefile（一）_haoel的博客-CSDN博客_makefile标签](https://blog.csdn.net/haoel/article/details/2886) && [Makefile由浅入深--教程、干货 - 知乎 (zhihu.com)](https://zhuanlan.zhihu.com/p/47390641)

## 概述

---

`makefile` 关系到了整个工程的编译规则，`makefile` 定义了一系列的规则来指定，哪些文件需要先编译，哪些文件后需要编译，哪些文件需要重新编译，甚者进行更复杂的功能操作，`makefile` 像 `shell`脚本一样，其中也可以执行操作系统的命令。

`makefile`带来的好处是-“自动化编译”，一旦写好，一个`make`命令，整个工程完全自动编译，极大提高了软件开发的效率。`make`是一个命令工具，是一个解释`makefile`中指令的命令工具。

## Makefile结构说明

---

`makefile` 主要包含了五个东西：变量定义，显示规则，隐晦规则，文件标示和注释。

1. 变量定义。在`makefile`中我们需要定义一系列的变量，一般是字符串，当`makefile`被执行时，其中的变量都会被扩展到相应的引用位置上。
    
2. 显示规则。说明了如何生成一个或者多个目标文件，由`makefile`的书写者明显指出，要生成的文件，文件的依赖文件，生成的文件。【可类似`shell`脚本】
    
3. 隐晦规则。由于make有自动推导功能，使用隐晦的规则可以让我们比较粗糙地简略书写`makefile`
    
4. 文件指示。其中包括了三个部分。
    
5. 注释。`Makefile`中只有行注释，使用 `#` 字符
    

## Makefile中的预定义变量

---

$* 　　不包含扩展名的目标文件名称。

$+ 　　所有的依赖文件，以空格分开，并以出现的先后为序，可能包含重复的依赖文件。

$< 　　第一个依赖文件的名称。

$? 　　所有的依赖文件，以空格分开，这些依赖文件的修改日期比目标的创建日期晚。

$@ 　 目标的完整名称。

$^ 　　所有的依赖文件，以空格分开，不包含重复的依赖文件。

$% 如果目标是归档成员，则该变量表示目标的归档成员名称。

## Go Makefile

---

使用`makefile`快速编译Go web程序，期望：

- 高级、简单的命令。比如：`compile` `start` `stop` `watch` 等等
    
- 管理具体项目环境的变量，它应该包含 `.env` 文件
    
- 开发模式，修改时自动编译
    
- 开发模式，修改时自动重启服务
    
- 开发模式，简洁地显示编译的错误信息
    
- 具体项目的GOPATH，可以在`vendor`目录维护依赖包
    
- 简化文件查看，
    

#### 1、环境变量

在`makefile`中 `include`为项目定义环境变量，第一行如下

```Plaintext
include .env
```

^^^

…………

#### final.最终版本

```Plaintext
include .env

PROJECTNAME=$(shell basename "$(PWD)")

# Go related variables.
GOBASE=$(shell pwd)
GOPATH="$(GOBASE)/vendor:$(GOBASE)
GOBIN=$(GOBASE)/bin
GOFILES=$(wildcard *.go)

# Redirect error output to a file, so we can show it in development mode.
STDERR=/tmp/.$(PROJECTNAME)-stderr.txt

# PID file will keep the process id of the server
PID=/tmp/.$(PROJECTNAME).pid

# Make is verbose in Linux. Make it silent.
MAKEFLAGS += --silent

## install: Install missing dependencies. Runs `go get` internally. e.g; make install get=github.com/foo/bar
install: go-get

## start: Start in development mode. Auto-starts when code changes.
start:
    bash -c "trap 'make stop' EXIT; $(MAKE) compile start-server watch run='make compile start-server'"

## stop: Stop development mode.
stop: stop-server

start-server: stop-server
    @echo "  >  $(PROJECTNAME) is available at $(ADDR)"
    @-$(GOBIN)/$(PROJECTNAME) 2>&1 & echo $$! > $(PID)
    @cat $(PID) | sed "/^/s/^/  \>  PID: /"

stop-server:
    @-touch $(PID)
    @-kill `cat $(PID)` 2> /dev/null || true
    @-rm $(PID)

## watch: Run given command when code changes. e.g; make watch run="echo 'hey'"
watch:
    @GOPATH=$(GOPATH) GOBIN=$(GOBIN) yolo -i . -e vendor -e bin -c "$(run)"

restart-server: stop-server start-server

## compile: Compile the binary.
compile:
    @-touch $(STDERR)
    @-rm $(STDERR)
    @-$(MAKE) -s go-compile 2> $(STDERR)
    @cat $(STDERR) | sed -e '1s/.*/\nError:\n/'  | sed 's/make\[.*/ /' | sed "/^/s/^/     /" 1>&2

## exec: Run given command, wrapped with custom GOPATH. e.g; make exec run="go test ./..."
exec:
    @GOPATH=$(GOPATH) GOBIN=$(GOBIN) $(run)

## clean: Clean build files. Runs `go clean` internally.
clean:
    @(MAKEFILE) go-clean

go-compile: go-clean go-get go-build

go-build:
    @echo "  >  Building binary..."
    @GOPATH=$(GOPATH) GOBIN=$(GOBIN) go build -o $(GOBIN)/$(PROJECTNAME) $(GOFILES)

go-generate:
    @echo "  >  Generating dependency files..."
    @GOPATH=$(GOPATH) GOBIN=$(GOBIN) go generate $(generate)

go-get:
    @echo "  >  Checking if there is any missing dependencies..."
    @GOPATH=$(GOPATH) GOBIN=$(GOBIN) go get $(get)

go-install:
    @GOPATH=$(GOPATH) GOBIN=$(GOBIN) go install $(GOFILES)

go-clean:
    @echo "  >  Cleaning build cache"
    @GOPATH=$(GOPATH) GOBIN=$(GOBIN) go clean

.PHONY: help
all: help
help: Makefile
    @echo
    @echo " Choose a command run in "$(PROJECTNAME)":"
    @echo
    @sed -n 's/^##//p' $< | column -t -s ':' |  sed -e 's/^/ /'
    @echo
```