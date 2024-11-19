---
title: docker-基础
tags: ["docker"]
date: "2024-09-28"
categories: ["docker"]
---

> https://yeasy.gitbook.io/docker_practice/

## 一、基本概念

- 镜像(`Image`)
- 容器(`Container`)
- 仓库(`Repository`)

理解以上三个概念，就能理解docker的生命周期

### 1.镜像

**Docker镜像**是一个特殊的文件系统，除了提供容器运行时所需的程序、库、资源、配置等文件，以及一些运行时所需的配置参数。镜像不包含任何动态数据，其内容在插件之后也不会被改变

**分层存储**，镜像采用了分层存储的架构，由一组文件系统组成的（多层文件系统联合组成）。在构建镜像时，会一层一层构建，后一层依赖于上一层，后一层上的任何改变都只会发生在本层，不会干涉到上一层。因此构建镜像的时候，需要对每层需要添加的东西尽量加最少最有必要的东西，减少额外的东西

分层存储的特征还使得**镜像的复用，定制**更为容易

### 2.容器

容器是镜像运行时的实体，可以被创建、启动、停止、删除暂停等

> 镜像(Image)和容器(container)的关系，就像是面向对象程序设计中的`类` 和`实例` 一样

容器的实质是进程，运行于属于自己的独立的命名空间。因此容器可以拥有自己的`root` 文件系统，网络配置、进程空间等，运行在一个隔离的环境。这样的隔离特性，使得容器封装的应用比直接在宿主运行更加安全

容器也是分层存储，是**以镜像为基础层**，在其上创建一个当前容器的存储层，这个层是为容器运行时进行读写而准备的，称为**容器存储层**

容器存储层的生命周期跟容器一样，当容器消亡时，容器存储层也随之消亡，因此任何保存于容器存储层的信息都会随着容器的删除而丢失

> Dokcer最佳实践的要求，容器不应该向其存储层写入任何数据，容器存储层保存无状态化，所有的文件写入操作，都应该使用数据卷、或者绑定宿主目录
>
> 数据卷独立于容器，使用容器卷，容器的删除或者重写运行之后，数据都不会丢失

### 3.仓库

Docker Register：提供一个集中的存储、分发镜像的服务

一个**Docker Register**可以包含多个**仓库（****Repository****）;**每个仓库可以包含多个**标签（Tag）,**每个标签对应一个镜像

可以通过`<Repository Name>:<Tag Name>` 的格式来指定具体的软件是那个版本的镜像

仓库名以两段路径形式出现，比如`jwilder/nginx-proxy` 前者是Docker Registry多用户环境下的用户名，后者是对应的软件名

### Docker Registry 公开服务

Docker Registry公开服务是开放给用户使用、允许用户管理镜像的Registry服务。

最常见的是Docker Registry公开服务是官方的[hub.docker.com](https://hub.docker.com/)，也是默认的Registry

也可以使用国内的镜像网站

### 私有Docker Registry

用户可以在本地搭建私有的Docker Registry。Docker提供了Docker Registry镜像，可以直接使用搭建私有Registry服务

## 二、镜像

### 1.获取镜像

从Docker镜像仓库获取镜像的命令是 `docker pull`

```Dockerfile
docker pull [选项] [Docker Registry 地址[:端口号]/] 仓库名[:标签]
```

具体选项可以从`docker pull --help` 命令查看，

- Docker镜像仓库地址：地址格式一般为 `<域名/IP>[:端口号]`。默认地址是 Docker Hub

- 仓库名：仓库名是两段式，即`<用户名>/<软件名>`.对于Docker Hub，如果不给出用户名，默认为 `library`，也就是官方镜像


```Bash
$ docker pull ubuntu:18.04
```

上面命令没有给出Docker镜像仓库地址，默认从`Docker Hub`获取镜像。而镜像名称是`ubuntun:18.04`,因此会获取官方镜像 `library/ubuntun`仓库中标签为`18.04`的镜像

### 2.运行

有了镜像后，我们就能够以这个镜像为基础启动并运行一个容器。以上面的`ubuntu:18.04`为例，如果我们打算启动`ubuntu>>bash`并且进行交互式操作的话，可以执行下面命令

```Bash
$ docker run -it --rm \
        ubuntu:18.04 \
        bash
```

`docker run`就是运行容器的命令

- `-it`：是两个参数，一个是`-i`：交互式操作、一个是`-t`：终端。这里打算进入`bash`执行命令并查看返回结果，
- `--rm`：这个参数是说容器退出后随之将其删除。默认情况下，为了排障需求，退出的容器并不会立即删除，除非手动 `docker rm`。我们这里只是随便执行个命令，看看结果，不需要排障和保留结果，因此使用 `--rm` 可以避免浪费空间。
- `ubuntu:18.04`：这是指用 `ubuntu:18.04` 镜像为基础来启动容器。
- `bash`：放在镜像名后的是 **命令**，这里我们希望有个交互式 Shell，因此用的是 `bash`。
通过 `exit` 退出了这个容器。

### 列出镜像

使用`docker image ls`命令，可以列出已经下载下来的镜像

```Bash
$ docker image ls
Emulate Docker CLI using podman. Create /etc/containers/nodocker to quiet msg.
REPOSITORY                TAG         IMAGE ID      CREATED      SIZE
docker.io/library/ubuntu  18.04       e28a50f651f9  3 weeks ago  65.5 MB
```

列表包含了`仓库名`、`标签`、`镜像ID`、`创建时间`、`所占用的空间`

**镜像 ID** 则是镜像的唯一标识，一个镜像可以对应多个 **标签**。

#### 1.镜像体积

`docker image ls` 列表中的镜像体积总和并非是所有镜像实际硬盘消耗。由于 Docker 镜像是多层存储结构，并且可以继承、复用，因此不同镜像可能会因为使用相同的基础镜像，从而拥有共同的层。由于 `Docker` 使用 `Union FS`，相同的层只需要保存一份即可，因此实际镜像硬盘占用空间很可能要比这个列表镜像大小的总和要小的多。

可以使用 `docker system df`命令来查看镜像、容器、数据卷所占用的空间

#### 2.虚悬镜像

一个特殊的镜像，这个镜像既没有仓库名，也没有标签，均为 `<none>`。：

```Bash
<none>               <none>              00285df0df87        5 days ago          342 MB
```

这个镜像原本是有镜像名和标签的，原来为 `mongo:3.2`，随着官方镜像维护，发布了新版本后，重新 `docker pull mongo:3.2` 时，`mongo:3.2` 这个镜像名被转移到了新下载的镜像身上，而旧的镜像上的这个名称则被取消，从而成为了 `<none>`。除了 `docker pull` 可能导致这种情况，`docker build` 也同样可以导致这种现象。由于新旧镜像同名，旧镜像名称被取消，从而出现仓库名、标签均为 `<none>` 的镜像。这类无标签镜像也被称为 **虚悬镜像(dangling image)** ，可以用下面的命令专门显示这类镜像：

```Bash
$ docker image ls -f dangling=true
REPOSITORY          TAG                 IMAGE ID            CREATED             SIZE
<none>              <none>              00285df0df87        5 days ago          342 MB
```

一般来说，虚悬镜像已经失去了存在的价值，是可以随意删除的，可以用下面的命令删除。

```Bash
$ docker image prune
```

#### 3.中间层镜像

为了加速镜像构建、重复利用资源，Docker会利用**中间层镜像**。使用在使用一段时间过后，可能会看到一些依赖的中间层镜像。默认的 `docker image ls`列表中只会显示顶层镜像，如果希望**显示**包括**中间层镜像所在内的所有镜像**的话，需要加`-a`参数

```Bash
$ docker image ls -a
```

#### 4.列出部分镜像

不加任何参数的情况下，`docker image ls` 会列出所有顶层镜像，但是有时候我们只希望列出部分镜像。`docker image ls` 有好几个参数可以帮助做到这个事情。

根据仓库名列出镜像

```Bash
$ docker image ls ubuntu
REPOSITORY          TAG                 IMAGE ID            CREATED             SIZE
ubuntu              18.04               f753707788c5        4 weeks ago         127 MB
ubuntu              latest              f753707788c5        4 weeks ago         127 MB
```

列出特定的某个镜像，也就是说指定仓库名和标签

```Bash
$ docker image ls ubuntu:18.04
REPOSITORY          TAG                 IMAGE ID            CREATED             SIZE
ubuntu              18.04               f753707788c5        4 weeks ago         127 MB
```

除此以外，`docker image ls` 还支持强大的过滤器参数 `--filter`，或者简写 `-f`。之前我们已经看到了使用过滤器来列出虚悬镜像的用法，它还有更多的用法。比如，我们希望看到在 `mongo:3.2` 之后建立的镜像，可以用下面的命令：

```Bash
$ docker image ls -f since=mongo:3.2
REPOSITORY          TAG                 IMAGE ID            CREATED             SIZE
redis               latest              5f515359c7f8        5 days ago          183 MB
nginx               latest              05a60462f8ba        5 days ago          181 MB
```

想查看某个位置之前的镜像也可以，只需要把 `since` 换成 `before` 即可。

此外，如果镜像构建时，定义了 `LABEL`，还可以通过 `LABEL` 来过滤。

```Bash
$ docker image ls -f label=com.example.version=0.1
...
```

#### 5.以特定格式显示

默认情况下，`docker image ls` 会输出一个完整的表格，但是我们并非所有时候都会需要这些内容。比如，刚才删除虚悬镜像的时候，我们需要利用 `docker image ls` 把所有的虚悬镜像的 ID 列出来，然后才可以交给 `docker image rm` 命令作为参数来删除指定的这些镜像，这个时候就用到了 `-q` 参数。