--- 
title: docker-部署
tags: ["docker"]
date: "2024-09-28"
---

使用Docker 以及Docker Compose部署Go程序

## 为什么需要docker

> 使用docker的主要目标是其容器化。可以为应用程序提供一致的环境，而不依赖它运行的主机

---

### 部署示例

#### 1.准备代码

```Plaintext
package main

import (
        "fmt"
        "net/http"
)

func main() {
        http.HandleFunc("/", hello)
        server := &http.Server{
                Addr: ":8888",
        }
  fmt.Println("server startup...")
        if err := server.ListenAndServe(); err != nil {
                fmt.Printf("server startup failed, err:%v\n", err)
        }
}

func hello(w http.ResponseWriter, _ *http.Request) {
        w.Write([]byte("hello liwenzhou.com!"))
}
```

这里是简单代码

#### 2.创建Docker镜像

> 镜像(image)包含运行应用程序所需的所有东西——代码/二进制文件、运行时、依赖项以及所需的任何其它人间系统对象

简单讲，镜像是定义应用程序以及运行所需的一切

#### 3.编写Dockerfile

要创建Docker镜像(image)必须在配置文件中的指定步骤，这个文件默认称为`Dockerfile`

```Plaintext
FROM golang:alpine

# 为我们的镜像设置必要的环境变量
ENV GO111MODULE=on \
    CGO_ENABLED=0 \
    GOOS=linux \
    GOARCH=amd64

# 移动到工作目录：/build
WORKDIR /build

# 将代码复制到容器中
COPY . .

# 将我们的代码编译成二进制可执行文件app
RUN go build -o app .

# 移动到用于存放生成的二进制文件的 /dist 目录
WORKDIR /dist

# 将二进制文件从 /build 目录复制到这里
RUN cp /build/app .

# 声明服务端口
EXPOSE 8888

# 启动容器时运行的命令
CMD ["/dist/app"]
```

#### 4.Dockerfile解析

- **From**
    

使用了基础镜像 `golang:alpine`来创建镜像。这个镜像运行的是alpine Linux发行版，该发行版的大小很小并内置了Go。有大量公开可用的Docker镜像，请查看https://hub.docker.com/_/golang

- Env
    

用来设置编译阶段需要的环境变量

- WORKDIR,COPY,RUN
    
- EXPORT,CMD
    

声明服务端口，应用程序监听这个端口并通过这个端口对外提供服务。还定义了运行镜像执行的默认执行命令`CMD ["/dist/app"]`

---

### 构建镜像

在项目目录下面，在终端输入下面的命令创建镜像，并指定镜像名称为`go_app`

```Plaintext
docker build . -t go_app
```

等待构建结束，输出 `Successfully`

等输出 `Successfully`后，此时镜像已经准备好了，但是目前什么项目都没有，需要运行下面的代码来运行镜像。注：**运行中的镜像称为镜像**

```Plaintext
docker run -p 8888:8888 go_app
```

标志位`-p`来定义端口绑定，由于容器中的应用程序在端口8888上运行，这里绑定的主机端口也是8888。如果要绑定另一个端口，则可以使用 `-p $HOST_PORT:8888`

到这里就可以测试我们的程序是否工作正常，打开 http://127.0.0.1:8888 查看事先定义的响应内容。

---

### 分阶段构建示例

Go程序编译之后可得到一个可执行的二进制文件，在最终的镜像中不需要go编译器，也就是说我们只需要一个运行最终二进制文件的容器即可。

Docker的最佳实践之一是通过仅保留二进制文件来减小镜像大小，为此，我们将使用一种称为多阶段构建的技术

```Plaintext
FROM golang:alpine AS builder

# 为我们的镜像设置必要的环境变量
ENV GO111MODULE=on \
    CGO_ENABLED=0 \
    GOOS=linux \
    GOARCH=amd64

# 移动到工作目录：/build
WORKDIR /build

# 将代码复制到容器中
COPY . .

# 将我们的代码编译成二进制可执行文件 app
RUN go build -o app .

###################
# 接下来创建一个小镜像
###################
FROM scratch

# 从builder镜像中把/dist/app 拷贝到当前目录
COPY --from=builder /build/app /

# 需要运行的命令
ENTRYPOINT ["/app"]
```

使用这种技术，我们剥离了使用`golang:alpine`作为编译镜像来编译得到二进制可执行文件的过程，并基于`scratch`生成一个简单的、非常小的新镜像。我们将二进制文件从命名为`builder`的第一个镜像中复制到新创建的`scratch`镜像中。有关scratch镜像的更多信息，请查看https://hub.docker.com/_/scratch

---

### 附带其他文件的部署示例

web项目(前后端不分离)一般会有静态文件或者配置文件，需要拷贝到最终的镜像文件中

例如 `templates` | `static` | `conf` 三个文件的内容拷贝到镜像文件中

```Plaintext
FROM golang:alpine AS builder

# 为我们的镜像设置必要的环境变量
ENV GO111MODULE=on \
    CGO_ENABLED=0 \
    GOOS=linux \
    GOARCH=amd64

# 移动到工作目录：/build
WORKDIR /build

# 复制项目中的 go.mod 和 go.sum文件并下载依赖信息
COPY go.mod .
COPY go.sum .
RUN go mod download

# 将代码复制到容器中
COPY . .

# 将我们的代码编译成二进制可执行文件 bubble
RUN go build -o bubble .

###################
# 接下来创建一个小镜像
###################
FROM scratch

COPY ./templates /templates
COPY ./static /static
COPY ./conf /conf

# 从builder镜像中把/dist/app 拷贝到当前目录
COPY --from=builder /build/bubble /

# 需要运行的命令
ENTRYPOINT ["/bubble", "conf/config.ini"]
```

**Tips：** 这里把COPY静态文件的步骤放在上层，把COPY二进制可执行文件放在下层，争取多使用缓存。

---

### 关联其他容器

项目中使用了MySQL，可以选择使用如下命令启动一个MySQL容器，它的别名为`mysql8019`；root用户的密码为`root1234`；挂载容器中的`/var/lib/mysql`到本地的`/Users/docker/mysql`目录；内部服务端口为3306，映射到外部的13306端口。

```Plaintext
docker run --name mysql8019 -p 13306:3306 -e MYSQL_ROOT_PASSWORD=root1234 -v /Users/q1mi/docker/mysql:/var/lib/mysql -d mysql:8.0.19
```

这里需要修改一下我们程序中配置的MySQL的host地址为容器别名，使它们在内部通过别名（此处为mysql8019）联通。

```Plaintext
[mysql]
user = root
password = root1234
host = mysql8019
port = 3306
db = bubble
```

修改后记得重新构建`bubble_app`镜像：

```Bash
docker build . -t bubble_app
```

我们这里运行`bubble_app`容器的时候需要使用`--link`的方式与上面的`mysql8019`容器关联起来，具体命令如下：

```Bash
docker run --link=mysql8019:mysql8019 -p 8888:8888 bubble_app
```

---

### Docker Compose模式

除了像上面一样使用`--link`的方式来关联两个容器之外，我们还可以使用`Docker Compose`来定义和运行多个容器。

`Compose`是用于定义和运行多容器 Docker 应用程序的工具。通过 Compose，你可以使用 YML 文件来配置应用程序需要的所有服务。然后，使用一个命令，就可以从 YML 文件配置中创建并启动所有服务。

使用Compose基本上是一个三步过程：

1. 使用`Dockerfile`定义你的应用环境以便可以在任何地方复制。
    
2. 定义组成应用程序的服务，`docker-compose.yml` 以便它们可以在隔离的环境中一起运行。
    
3. 执行 `docker-compose up`命令来启动并运行整个应用程序。
    

我们的项目需要两个容器分别运行`mysql`和`bubble_app`，我们编写的`docker-compose.yml`文件内容如下：

```Plaintext
# yaml 配置
version: "3.7"
services:
  mysql8019:
    image: "mysql:8.0.19"
    ports:
      - "33061:3306"
    command: "--default-authentication-plugin=mysql_native_password --init-file /data/application/init.sql"
    environment:
      MYSQL_ROOT_PASSWORD: "root1234"
      MYSQL_DATABASE: "bubble"
      MYSQL_PASSWORD: "root1234"
    volumes:
      - ./init.sql:/data/application/init.sql
  bubble_app:
    build: .
    command: sh -c "./wait-for.sh mysql8019:3306 -- ./bubble ./conf/config.ini"
    depends_on:
      - mysql8019
    ports:
      - "8888:8888"
```

这个 Compose 文件定义了两个服务：`bubble_app` 和 `mysql8019`。其中：

##### bubble_app

使用当前目录下的`Dockerfile`文件构建镜像，并通过`depends_on`指定依赖`mysql8019`服务，声明服务端口8888并绑定对外8888端口。

##### mysql8019

mysql8019 服务使用 Docker Hub 的公共 mysql:8.0.19 镜像，内部端口3306，外部端口33061。

这里需要注意一个问题就是，我们的`bubble_app`容器需要等待`mysql8019`容器正常启动之后再尝试启动，因为我们的web程序在启动的时候会初始化MySQL连接。这里共有两个地方要更改，第一个就是我们`Dockerfile`中要把最后一句注释掉：

```Plaintext
# Dockerfile
...
# 需要运行的命令（注释掉这一句，因为需要等MySQL启动之后再启动我们的Web程序）
# ENTRYPOINT ["/bubble", "conf/config.ini"]
```

第二个地方是在`bubble_app`下面添加如下命令，使用提前编写的`wait-for.sh`脚本检测`mysql8019:3306`正常后再执行后续启动Web应用程序的命令：

```Plaintext
command: sh -c "./wait-for.sh mysql8019:3306 -- ./bubble ./conf/config.ini"
```

当然，因为我们现在要在`bubble_app`镜像中执行sh命令，所以不能在使用`scratch`镜像构建了，这里改为使用`debian:stretch-slim`，同时还要安装`wait-for.sh`脚本用到的`netcat`，最后不要忘了把`wait-for.sh`脚本文件COPY到最终的镜像中，并赋予可执行权限哦。更新后的`Dockerfile`内容如下：

```Plaintext
FROM golang:alpine AS builder

# 为我们的镜像设置必要的环境变量
ENV GO111MODULE=on \
    CGO_ENABLED=0 \
    GOOS=linux \
    GOARCH=amd64

# 移动到工作目录：/build
WORKDIR /build

# 复制项目中的 go.mod 和 go.sum文件并下载依赖信息
COPY go.mod .
COPY go.sum .
RUN go mod download

# 将代码复制到容器中
COPY . .

# 将我们的代码编译成二进制可执行文件 bubble
RUN go build -o bubble .

###################
# 接下来创建一个小镜像
###################
FROM debian:stretch-slim

COPY ./wait-for.sh /
COPY ./templates /templates
COPY ./static /static
COPY ./conf /conf


# 从builder镜像中把/dist/app 拷贝到当前目录
COPY --from=builder /build/bubble /

RUN set -eux; \
        apt-get update; \
        apt-get install -y \
                --no-install-recommends \
                netcat; \
        chmod 755 wait-for.sh

# 需要运行的命令
# ENTRYPOINT ["/bubble", "conf/config.ini"]
```

所有的条件都准备就绪后，就可以执行下面的命令跑起来了：

```Bash
docker-compose up
```