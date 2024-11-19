---
title: dockerfile-学习
tags: ["docker"]
date: "2024-09-28"
categories: ["docker"]
---

学习自
- [一篇文章带你吃透 Dockerfile - 掘金 (juejin.cn)](https://juejin.cn/post/7179042892395053113)
- [Dockerfile reference](https://docs.docker.com/engine/reference/builder/)
- [全网最详细的Docker-Compose详细教程 - 掘金 (juejin.cn)](https://juejin.cn/post/7042663735156015140)
- [docker compose 配置文件 .yml 全面指南 - 知乎 (zhihu.com)](https://zhuanlan.zhihu.com/p/387840381)
- [compose-spec/spec.md at master · compose-spec/compose-spec · GitHub](https://github.com/compose-spec/compose-spec/blob/master/spec.md)

## 前言
---

学习Dockers前期，通过Docker的官方镜像仓库拉取里面的镜像，根据这些镜像创建出容器并运行

实际上，Docker官方镜像也是通过一定的方式构建出来的，只要弄清其中的逻辑，我们也可以仿照官方镜像的构建过程，构建出自己的镜像

`Dockerfile`就是这样一个用于描述Docker镜像构建过程的文本文件，dockerfile可以包含多条构建指令，以及相关的描述

### 1.什么是容器

容器是计算机上的沙盒进程，与主机上的其它进程隔离，这种隔离利用了`内核命名空间和cgroups`。简而言之容器是：

- 是`image`的可运行实例

- 可以在本地计算机、虚拟机上运行或部署到云中

- 是可移植的

- 与其它容器隔离，并运行自己的软件，二进制文件和配置


### 2.什么是容器映射

当容器运行时，它使用了隔离的文件系统。这个自定义的文件系统由容器映像`container image`提供。因为image包含了容器的问价系统，使用image必须包含所有的运行应用程序所必须的所有东西——依赖项、配置、脚本、二进制文件等等。

> 沙盒进程是指在计算机系统中，为了保障安全和隔离性而采用的一种技术，将应用程序运行在一个受限制的环境中，限制它们能访问的资源和操作范围，从而避免恶意程序和授权程序对系统的破坏

### 3.容器是怎么运行的

当一个容器运行时，它为其文件系统使用来image的各个层。每个容器都有自己的命名空间来创建/更新/删除文件。在另一个容器中不会看到任何更改，即使它们使用相同的image

### 4.容器卷[container volumes]

每个容器启动时都是从容器的定义开始的。在容器中可以创建、更新和删除文件，但当容器被删除时，这些改变将回丢失，所有更变都被隔离在各个容器中

卷：提供了将容器的特定文件系统路径链路到主机的能力。如果在主机上的某个文件被挂载，那么当容器中该文件路径下的文件发送更改时，我们在主机上同样也可以看到更改。同样的，启动另一个挂载了同一个文件目录的容器，它也可以访问到相同的文件

## 镜像构建原理

---

### 1.Docker架构模式

![](https://rt5bap83jl.feishu.cn/space/api/box/stream/download/asynccode/?code=ODNkMzZjNzQ1MTljOTE0ZThhNjliYjMwODFiMjQ0NTJfSVlseWZldFNjR0l6QVpDbzFMdmNhYXg1TWRZb1oxUjZfVG9rZW46RjhBeWJoWkZpb2ZZbll4WEd2dGN3RXJHbkxoXzE3MjE4NDA4ODE6MTcyMTg0NDQ4MV9WNA)

`docker`使用了**client**/**server**的架构模式。构建镜像时，用户在**dockers** **client**输入构建命令。**docker**引擎以 `REST API`的形式，像 **docker** **daemon**发送构建请求，如何dockers daemon就根据构建请求的内容，开始镜像构建的工作，并向Client持续放回构建过程的信息。

### 2.镜像分层模型

---

**docker**镜像是用于创建容器的只读模板，是通过 **Dockerfile**中定义的指令构建而成的，构建结束后，会在原有的镜像层上生成一个新的镜像层，如下所示

![](https://rt5bap83jl.feishu.cn/space/api/box/stream/download/asynccode/?code=NmE5Yjk1OTNiMTc0MDI5YmU0NGZiNTNjZDU4NDQ5MDFfZmlPNWJYSnRaQ0RUSnJZNXpGSmN0anNFN1V6WGw4VkRfVG9rZW46RU9scmI4N0Jrb2RQVHJ4cVJFM2NwNlNtblBkXzE3MjE4NDA4ODE6MTcyMTg0NDQ4MV9WNA)

在 tomcat 镜像创建一个容器后，会在tomcat镜像之上新创建一个可写的容器层，在容器中写文件时，会保存到这个容器层中

![](https://rt5bap83jl.feishu.cn/space/api/box/stream/download/asynccode/?code=MWU3YzUzYTM5OTE3NmZkZmEyNjhiYjZhYjljZTFiOTZfaTY2T1RORTY0UEVXWVJ0cnZ4RGxnSVE2ZGE0QWtsVlVfVG9rZW46Vk5McWI1RVV1b2h5WFV4aHBPM2NrcTNRbnVnXzE3MjE4NDA4ODE6MTcyMTg0NDQ4MV9WNA)

### 3.基础镜像与父级镜像

---

用于构建基础镜像的 **Dockerfile** 不指定父级镜像，Docker约定使用如下形式基础镜像

```Dockerfile
FROM scratch
```

这里的 `scratch`是一个空镜像，可以从零开始构建镜像，常用来构建最小镜像，如`busybox`，`debian`，`alpine`等镜像，省去很多linux命令，因此很小。一般，不需要自己去构建基础镜像。

构建自定义镜像时，通过**FROM**指定使用说明父级镜像。例如，官方的**tomcat**命令没有yum，vim等命令，但是我们可以将**tomcat**镜像作为父级镜像，然后安装想要的命令，这样在容器中就可以使用了。

![](https://rt5bap83jl.feishu.cn/space/api/box/stream/download/asynccode/?code=ZDlkNDU3NWIxM2ExYmJmNDAzMGFhZmJkM2Q5ZGI2YzJfRUEwazJiZmgzallqUHlaYlBKSlJGc1VNWVFVMVVKcUZfVG9rZW46WmlDcmJBbVZxb2FRS0t4VUNIbmNhaVMxbk5oXzE3MjE4NDA4ODE6MTcyMTg0NDQ4MV9WNA)

### 4.构建上下文 / build context

---

**Client** 向 **Docker** **daemon** 发送的构架请求包含两部分，第一部分是 **Dockerfile**文件，第二部分是**构建上下文**

构建上下文是一些文件集合，这些文件可以是指定路径下的文件，也可以是远程资源中指定路径下的文件，在构建过程中，Docker daemon 可以访问这些文件，并执行相应的操作[理解：访问配置文件]

- 路径上下文


构建命令中指定具体路径，该路径下的所有文件即为构建上下文，这些文件被打包送给Docker daemon中，然后被解压

假使一个项目的文件结构如下

```Plaintext
demo
|--Dockerfile
|--src
|--test
|--node_modules
```

在项目根目录执行下面的构建命令

```Dockerfile
docker build -t img-tag .
```

构建请求的第一部分是**Dockerfile**，这个文件在当前目录下，文件是默认名称，因此省略，

相当于默认加上了 **-f Dockerfile**, 该Dockerfile内容如下

```Dockerfile
FROM busybox
WORKDIR /src
COPY src .
```

构建请求的第二部分是 `.`这个点代表当前，此时当前目录就是此次的构建的上下文，Docker引擎会整理该目录下的所有文件，把不被 `.dockerignore`中的规则所的文件都发送到Docker daemon中，如下所示

![](https://rt5bap83jl.feishu.cn/space/api/box/stream/download/asynccode/?code=ZWYzNWIwOTExNWEyZDE1MWViMDUzZWI1NTJlY2Y5MDBfN3VzcmhGU0U3WDlJbVZ1aDU2TngzSm1pckQ4bWNjSUFfVG9rZW46S1dTOWJHSzVrb2ZPVTN4QVMyTWN4U1E3bjhkXzE3MjE4NDA4ODE6MTcyMTg0NDQ4MV9WNA)

如果此时位于项目根目录的上一级目录，构建命令如下

```Dockerfile
docker build -t img-tag -f ./demo/Dockerfile ./demo/
```

- URL上下文


Docker 还支持利用远程仓库URL构建镜像，此时指定的远程仓库目录就充当了构建上下文

```Bash
docker build https://gitee.com:user/my-repo.git#master:docker
```

以上构建命令指定了一个 Gitee 项目的 master 分支，冒号（:）之前是 Git 检出的目标 URL, 冒号之后的 docker 是远程仓库根目录下的一个子目录，此时这个子目录就是构建上下文

Docker client 执行构建命令时，Docker 引擎首先会将远程仓库的 master 分支拉取到本地的一个临时目录中，然后将其中的 docker 目录下的文件作为构建上下文发送到 Docker daemon 中。拉取远程文件之后，又回到了路径上下文的步骤，如下图所示

![](https://rt5bap83jl.feishu.cn/space/api/box/stream/download/asynccode/?code=YmQyZDhlNzE5MWEyNWMzYzcyNzYzZGY2ZjNhMGMyZTVfd1BUeUhQaU01dE84N1JpWTZWOGFRZldyb0p3MEhxbEhfVG9rZW46UXRpVmJLb3VOb1RFb0h4REYyUWNOdHk3bjJjXzE3MjE4NDA4ODE6MTcyMTg0NDQ4MV9WNA)

- 省略上下文


如果 Dockerfile 中的指令不需要对任何文件进行操作，可以省略构建上下文，此时不会向 Docker daemon 发送额外的文件，这可以提高构建速度

```Dockerfile
docker build -t my-hello-world:latest -<<EOF
FROM busybox
RUN echo "hello world"
EOF
```

### 5.构建缓存

---

迭代过程中，Dockerfile对于的资源会被经常修改，因此需要频繁重新构建镜像，Docker为了提高构建速度，设计了多种优化方案，其中最重要的是**构建缓存**

示例：说明构建缓存是如何工作的，Dockerfile如下

```Dockerfile
# syntax=docker/dockerfile:1
FROM ubuntu:latest

RUN apt-get update && apt-get install -y build-essentials
COPY main.c Makefile /src/
WORKDIR /src/
RUN make build
```

镜像构建过中，dockerfile 中的指令会从上往下执行，每一个构建步骤的结果都会被缓存起来，例如

![](https://rt5bap83jl.feishu.cn/space/api/box/stream/download/asynccode/?code=NDY5MmEyMmQzNGVlZmM3YTdiNDcyN2UwMjU5Y2Y3MmVfQ2NnRHhMc3ZXMVhPc1BMdUFVNk9SRDAwZnJLTjR0RmZfVG9rZW46RkxWTWJXSnl4b0huWk54RlVENWNCaTVTbmlYXzE3MjE4NDA4ODE6MTcyMTg0NDQ4MV9WNA)

此时再次构建，会直接使用缓存中的结果(Using cache)

这里假设修改了main.c 中的代码，再次构建时，从 `COPY main Makefile /src/`这条指令开始，后续构建缓存都会失效，如下图所示

![](https://rt5bap83jl.feishu.cn/space/api/box/stream/download/asynccode/?code=ODY5NjUwYTUwMmUxZWIyYzRmY2I3YTg5ZjdlMGZmZjdfMG5vQ0pvOEZlV3N3NGRTVW9VQUs5WFJRSVpOa1dMS09fVG9rZW46VU5EYWJETE01b1BXRVd4Q2lHVmNveEcwbjZnXzE3MjE4NDA4ODE6MTcyMTg0NDQ4MV9WNA)

如果不想使用构建缓存，执行构建命令时，可以传入 `--no-cahe`

### 6.镜像构建过程

Docker Client 执行构建命令后，会经过以下步骤构建出最终镜像

1. 确定构建上下文，如果构建上下文中有 .dockerignore 文件，解析该文件的匹配规则，将构建上下文中被匹配的文件资源排除

2. 将 Dockerfile 和构建上下文发送给 Docker daemon

3. Docker daemon 收到构建请求。以下的步骤都由 Docker daemon 完成，省略主语

4. 逐条校验 Dockerfile 中的指令是否合法，如果不合法，立即结束构建。这一步可以确定一共有多少个构建步骤，便于后续分步构建时显示当前步骤，如 **Step 1/2**

5. 逐条执行 Dockerfile 中的指令，每条指令都新创建一层。会生成临时 container 用于执行命令，该步骤结束后删除临时容器

6. 生成最终镜像


## .dockerignore

---

这个文件需要遵循一定的语法规则

1. 以 # 开头的行是备注，不会被解析为匹配规则

2. 支持 ? 通配符，匹配单个字符

3. 支持 * 通配符，匹配多个字符，只能匹配单级目录

4. 支持 ** 通配符，可匹配多级目录

5. 支持 ! 匹配符，声明某些文件资源不需要被排除

6. 可以用 .dockerignore 排除 Dockerfile 和 .dockerignore 文件。Docker Client 仍然会将这两个文件发送到 Docker daemon，因为 Docker 底层需要。但 ADD 和 COPY 指令就无法操作这两个文件了


示例：

```Plaintext
# this is a .dockerignore demo

*/demo*
*/*/demo*
demo?
**/mydemo*
```

## Dockerfile

---

**Dockerfile**时一个用于描述Docekr镜像构建过程的文本文件，包含多条构建指令，以及相关的描述

Dockerfile的构建指令需要遵循如下的语法

```Dockerfile
# Comment
INSTRUCTION arguments
```

以 `#`开头的行绝大部分是注释，还有一小部分是解析器指令

构建指令分两个部分，第一部分是指令，第二部分是指令参数。

#### 1.解析器指令 / parse directive

解析器指令是以 `#`开始，用来提示解释器对 Dockerfile进行特殊处理，构建过程中它不会增加镜像层，也不会出现在构建过程

解析器指令是可选的

```Dockerfile
# directive=value
# 解析器指令需要在空行，注释，构建指令之前
```

**注意事项**

- 同一解析器指令不能重复

- 不区分大小写，按照惯例，推荐小写

- 空行、注释、构建指令之后，Docker 不再查找解析器指令，都当成注释

- 按照惯例，解析器指令位于 Dockerfile 的第一行，在后面添加空行

- 行内的空格被忽略，不支持跨行


Docker 目前支持两种解析器指令

1. syntax

2. escape


**syntax** 解析器指令，只有使用 **BuildKit** 作为构建器时才生效

**escape** 解析器指令，用于指定在 Dockerfile 中使用转义字符

在 Dockerfile 中，escape 默认为 \

```Dockerfile
# escape=\
复制代码
```

但 Windows 系统中的 \ 是路径分隔符，推荐将 escape 替换为 `，这和 PowerShell 是一致的

```Dockerfile
# escape=`
```

#### 2.常见指令解析

|   |   |   |
|---|---|---|
|序号|指令名|功能描述|
|1|FROM|指定基础镜像或者父级镜像|
|2|LABEL|为镜像添加元数据|
|3|ENV|设置环境变量|
|4|WORKDIR|指定后续指令的工作目录，类似于Linux中的cd命令|
|5|USER|指定当前构建阶段以及容器运行时的默认用户，以及可选的用户组|
|6|VOLUME|创建具有指定名称的挂载数据卷，用于数据持久化|
|7|ADD|将构建上下文中指定目录下的文件复制到镜像文件按系统的指定位置|
|8|COPY|功能与语法与ADD类似，但是不会自动解压文件，也不能访问网络资源|
|9|EXPOSE|约定容器运行时监听的端口，通常用于容器与外界之间的通信|
|10|RUN|用于构建镜像过程中执行目录|
|11|CMD|构建镜像成功后，所创建的容器启动时执行的命令，常与ENTRYPOINT结合使用|
|12|ENTRYPOINT|用于配置容器以可执行的方式运行，常与CMD结合使用|

**FROM**

指定基础镜像或父级镜像

```Dockerfile
FORM [--platform=<platform>] <image> [AS <name>]
FORM [--platform=<platform>] <image>[:<tag>] [AS <name>]
FORM [--platform=<platform>] <image>[@<digest>] [AS <name>]
```

1. `tag`或`digest`是可选项，默认为**latest**版本为基础镜像

2. 如果不以任何镜像为基础，使用：`FORM scratch`.**scratch**是一个空镜像，用于构建最小镜像


**LABEL**

为镜像添加元数据

```Dockerfile
LABEL <key>=<value> <key>=<value> <key>=<value>...
示例:
LABEL auth="ch" \
          version="1.0.0" \
          decription="Dockerfile"
```

1. 使用`LABEL`定义键值对结构的元数据，一个**LABEL**可指定多个元数据

2. 定义元数据值时，尽量使用双引号

3. 当前镜像可以继承继承镜像或者父级镜像中的元数据时，可以覆盖

4. 可使用以下命令查看元数据


```Dockerfile
docker image inspect -f='{{json .ContainerConfig.Labels}}' my-image
```

**ENV**

设置环境变量

```Dockerfile
ENV <key>=<value>...
ENV <key> <value>
```

1. 当前镜像可以继承基础镜像或者父级镜像中的环境变量，也可以覆盖

2. 使用`ENV`指定定义的环境变量，最终会持久化到容器中

3. 运行容器时，可以通过`--env =`或者`-e =`覆盖镜像定义中的环境变量

4. 对只使用在镜像构建过程中的变量，推荐使用`ARG`，或者内环境变量，这样不会被持久化到最终的镜像中


> 内环境变量示例：`RUN TEMP="no persisit"`

1. 查看最终镜像中的环境变量


```Dockerfile
docker image inspect -f='{{json .ContainerConfig.Env}}' my-image
```

**WORKDIR**

指定后续指令的工作目录，类似**linux**中的cd命令

```Dockerfile
WORKDIR /path/to/workdir
```

使用Dockerfile中设置的环境变量

```Dockerfile
ENV DIR_PATH=/demo
WORKDIR $DIR_PATH/$DIR_NAME
RUN pwd
```

构建镜像时，pwd 的输出结果是 /demo，因为 $DIR_NAME 未显示指定，直接忽略

1. 默认的工作目录是`/`

2. 可以使用Dockerfile中显示指定的环境变量，包括父级镜像中的环境变量

3. 父级镜像可能设置工作目录，最佳实践是显示设置当前镜像的工作目录


**USER**

指定当前构建阶段以及容器运行时的默认用户，以及可选的用户组

```Dockerfile
USER <user>[:<group>]
USER <user>[:<GID>]
USER <UID>[:<group>]
USER <UID>[:<GID>]
```

1. 使用USER指定用户后，Dockerfile中构建镜像的`RUN`,`CMD`,`ENTRYPOINT`指令都会使用该用户，同时这个用户也是容器运行时的默认用户

2. 不指定用户组，使用默认用户组**root**

3. 运行容器时，可以使用`-u`参数覆盖Dockerfile中默认的用户


**VOLUME**

创建具有指定名称的挂载数据卷，用于数据持久化

```Dockerfile
VOLUME ["volume1","volume2",...]
VOLUME volume1 volume2 ...
```

数据卷的特征以及作用：

- 数据持久化，避免容器重启后丢失重要数据

- 修改数据卷时不会对容器产生影响，防止容器不断膨胀

- 有利于多个容器共享数据


**ADD**

将构建上下文中指定目录下的文件**(src)**复制到镜像文件系统的指定位置**(dest)**

```Dockerfile
ADD [--chown=<user>:<group>][--checksum=<checksum>]<src>... <dest>
ADD [--chown=<user>:<group>]["<src>", ..."<dest>"]
ADD <git ref> <dir>
```

1. 如果`ADD`指令对应的src资源有变更，Dockerfile中这条指令后的**构建缓存**都会失效

2. Dockerfile中`--chown`特性只有在linux下才有效，windows是无效的

3. src支持通配符

4. dest必须是文件夹，用以存放文件

5. 如果src是**压缩资源**，将会被解压为一个文件

6. 如果 src 是远程 URL, 并且 dest 不以 / 结尾，Docker 从 URL 下载文件，存到 dest 中

7. 如果 src 是远程 URL，URL 中含有非空路径，并且 dest 以 / 结尾，Docker 会推断文件名，根据 URL 中的路径，在目标位置创建相同路径，将下载的文件放入其中

8. dest 可以是镜像文件系统下的绝对路径，或者是 WORKDIR 下的相对路径

9. 如果 dest 不是以 / 结尾，Docker 会把它当成普通文件，src 中的内容会被写入这个文件中

10. 如果目标位置下的某些目录不存在，会自动创建

11. ADD 添加网络资源时不支持身份认证，可以使用 RUN wget 或者 RUN curl 实现这个功能


**COPY**

功能与**ADD**类似，但是不会自动解压文件，也不能访问网络资源

```Dockerfile
COPY [--chown=<user>:<group>] <src>... <dest>
COPY [--chown=<user>:<group>] ["<src>",... "<dest>"]
```

**EXPOSE**

约定容器运行时监听的端口，通常用于容器与外界之间的通信

```Dockerfile
EXPOSE <port> [<port>/<protocol>...]
```

1. 支持 TCP 或者 UDP 协议，如果不显式指定协议，默认使用 TCP 协议

2. 需要同时以 TCP 和 UDP 协议的方式暴露同一个端口时，需要分别指定

3. EXPOSE 并不会真正将端口发布到宿主机，而是作为一种约定，让镜像使用者在运行容器时，用 **-p** 分别发布约定端口，或者 **-P** 发布所有约定端口

4. 如果没有暴露端口，运行容器是也可以通过 **-p** 的方式映射端口


**RUN**

用于构建镜像过程中执行命令，有两种执行方式

第一种，以**shell**方式运行

```Bash
RUN <command>
RUN echo "Hello Dockerfile"
```

第二种，以**exec**的方式运行

```Bash
RUN ["executable","param1","param2"...]
```

**CMD**

构建镜像成功后，所创建的容器启动时执行的命令

```Dockerfile
CMD command param1 param2 #shell
CMD ["executable","param1","param2"] #exec
CMD ["param1","param2"] #作为ENTRYPOINT的默认参数，是exec方式的特殊形式
```

1. Docker种只有一条`CMD`指令生效，在多条CMD指令存在的情况下，只有最后一条生效

2. 虽然Dockerfile中只有一条CMD生效，但每一条CMD指令会新增一个镜像层，所有推荐只定义一条CMD指令，使用`&&`连接多个指令

3. exec方式是通过JSON数组的方式进行解析的，因此需要双引号

4. 与RUN指令不同，RUN指令是在构建指令的过程中执行，CMD命令是在容器启动时执行

5. `docker run`后的命令行参数会覆盖CMD中的命令


**ENTRYPOINT**

用于配置容器以可执行的方式运行。有两种形式

```Dockerfile
ENTRYPOINT ["executable","param1","param2"] #推荐
ENTRYPOINT command param1 param2
```

1. Dockerfile中只有最后一条`ENTRYPOINT`指令生效

2. 运行容器时，docker run --entrypoint 覆盖该指令

3. shell 形式的 ENTRYPOINT 会使 CMD 命令 和 docker run


![](https://rt5bap83jl.feishu.cn/space/api/box/stream/download/asynccode/?code=YjBiYWU0ZTYwYWYyODYxMTIyMzkzZWMzMDY5ZjQ3YWJfZ1NYeEd4akFJUGl3UGQzM3ozaDdTZG5hQTFSWFZXZ2lfVG9rZW46VGdWYmJMQlUxbzF3T3V4QVh0ZGNDdzVGbmtjXzE3MjE4NDA4ODE6MTcyMTg0NDQ4MV9WNA)

1. 中的命令行参数失效。它有一个缺点，ENTRYPOINT 命令将作为 /bin/sh -c 的子命令，不会传递信号。比如，停止容器时，容器内接收不到 SIGTERM 信号，这并不是预期的效果，可以在命令前添加 exec 来解决，如 ENTRYPOINT exec top -b

2. 指定 ENTRYPOINT 后，CMD 的内容将作为默认参数传给 ENTRYPOINT 指令，形如

3. 如果 CMD 是在基础镜像中定义的，当前镜像定义的 ENTRYPOINT 会将 CMD 的值重置为空值，这种情况下，需要重新定义 CMD


# Docker-Compose

docker-compose通过一个声明式的配置文件描述整个应用，从而使用一条命令即可完成部署

docker-compose同使用**YAML**文件来定义多级服务，在使用时默认使用文件名`docker-compose.yml`，也可以在docker compose运行时使用`-f`参数来指定具体文件

**compose**的优点

- 在单主机上建立多个隔离环境，Compose使用项目名称将环境彼此隔离，可以在多个不同的上下文中使用此项目名称

- 创建容器时保留卷数据

- 仅重新创建以更改的容器，当服务没有更改时，Compose会使用现有的容器

- 变量在环境之间组合重复使用


**多个配置文件**

可以为用一个项目配置多个compose文件，使用多个compose文件能够针对不同的环境或者不同的工作流自定义compose应用程序

默认情况下，compose读取两个文件，`docker-compose.yml`和一个可选`docker-compose.override.yml`文件

如果在两个文件中都定义了服务，compose会使用override进行合并配置

当配置文件的名称非默认情况时，可以使用`-f`指定Compose文件

```Bash
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d
```

**yaml**文件级

Docker compose的YAML文件包含有4个一级key:`version`,`services`,`networks`,`volumes`

- `version`:指定版本信息，通常位于文件的第一行。其定义了Compose文件格式的版本。

- `services`:用于定义不用的应用服务。Docker Compose会将每个服务部署在各种的容器中。

- `networks`:用于指引Docker创建新的网络。默认情况下，Docker Compose会创建bridge网络，这个是一个单主机网络，只能实现同一主机上容器的连接。可以使用driver属性指定不同的网络类型

- `volumes`用于指引Docker来创建新的卷


## **docker-compose.yml**的具体配置：

## 1.build

指定构建镜像的dockerfile的上下文路径，或者详细配置文件

```YAML
version: "3.9"
services:
        webapp:
                build: ./dir
```

或者更详细的写法

```YAML
version: "3.9"
services:
  webapp:
    build:
      context: ./dir
      dockerfile: Dockerfile-alternate
      args:
        buildno: 1
```

- **context** 上下文路径，可以是文件路径，也可以是到链接到 git 仓库的 url。当是相对路径时，它被解释为相对于 Compose 文件的位置。

- **dockerfile** 指定构建镜像的 Dockerfile 文件名

- **args** 构建参数，只能在构建过程中访问的环境变量

- **cache_from** 缓存解析镜像列表

- **labels** 设置构建镜像的元数据

- **network** 设置网络容器连接，`none` 表示在构建期间禁用网络

- **shm_size** 设置`/dev/shm`此构建容器的分区大小

- **target** 多阶段构建，可以指定构建哪一层


## 2.network

...累了，下次再写

```YAML
version: '3.9'
services:
  mysql:
    build:
      context: ./mysql
    environment:
      MYSQL_ROOT_PASSWORD: admin
    restart: always
    container_name: mysql
    volumes:
    - /data/edu-bom/mysql/test:/var/lib/mysql
    image: mysql/mysql:5.7
    ports:
      - 3306:3306
    networks:
      net:
  eureka:
    build:
      context: ./edu-eureka-boot
    restart: always
    ports:
      - 8761:8761
    container_name: edu-eureka-boot
    hostname: edu-eureka-boot
    image: edu/edu-eureka-boot:1.0
    depends_on:
      - mysql
    networks:
      net:
networks:
    net:
volumes:
    vol:
```

**docker compose常用命令**

- 构建并启动服务——`docker-compose up -d`

- 停止运行并删除服务——`docker-compose down`

- 列出所有运行容器——`docker-compose ps`

- 查看服务日志——`docker-compose logs`

- 构建或重建——`docker-compose build`

- 启动服务——`docker-compose start`

- 停止运行中的服务——`docker-compose stop`

- 重启服务——`docker-compose restart`