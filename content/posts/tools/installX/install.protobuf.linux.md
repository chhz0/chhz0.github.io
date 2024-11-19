---
title: Linux 下编译安装Protobuf
date: 2024-10-01

tags: ["install", "protobuf"]
categories: ["installX -- 安装"]
series: ["Install Guide"]
---

以Ubuntu22.04为例，使用CMake从源码安装Protobuf v3.25.4

前期准备：

首先安装

```shell
sudo apt install -y gcc g++ cmake git
```

cmake 版本高于 3.15

Ubuntu的官方源没有提供abseil安装包，需要手动安装

```shell
git clone https://github.com/abseil/abseil-cpp.git  
cd abseil-cpp  
mkdir build && cd build  
cmake -DABSL_BUILD_TESTING=ON -DABSL_USE_GOOGLETEST_HEAD=ON -DCMAKE_CXX_STANDARD=14 ..  
make  
sudo make install  
sudo ldconfig
```

开始安装`protobuf`

```shell
git clone -b v3.23.2 https://github.com/protocolbuffers/protobuf.git && cd protobuf  
git submodule update --init --recursive
cmake .  
make  
sudo make install .  
sudo ldconfig 
```

