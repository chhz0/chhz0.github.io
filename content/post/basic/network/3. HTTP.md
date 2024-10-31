--- 
title:  "[计网] HTTP"
subtitle: ""
tags:  ["计算机网络"]
date:  "2024-10-31"
---

接下来将从以下6个方面，逐渐学习和了解HTTP

1. HTTP基本概念
2. Get与Post
3. HTTP特征
4. HTTP缓存
5. HTTPS与HTTP
6. HTTP/1.1、HTTP/2、HTTP/3演变

![](https://rt5bap83jl.feishu.cn/space/api/box/stream/download/asynccode/?code=YzgxNTk2MGIwMjM0ODdhZWNiYjM1YTdhNTM0NTMwOTJfaDdMekY5THZXQ0plelVaR2lCV1ZWWGptTUZISUMzcElfVG9rZW46TU5pOWJ0elBEbzVIa0p4bzdvTGM1N1VybkxoXzE3MjE4Mzk5Nzc6MTcyMTg0MzU3N19WNA)

## **HTTP基本概念**

---

### **1.HTTP是什么？**

> HTTP是超文本传输协议，也就是**HyperText** **Transfer Protocol**

HTTP的名字【超文本传输协议】，可以拆成三个部分：

- 超文本
    
- 传输
    
- 协议
    

![](https://rt5bap83jl.feishu.cn/space/api/box/stream/download/asynccode/?code=MWVjMWE4ZmI3M2M3YjczMWRmMDE3OWVmZjUwYTE0ODBfRXhVcm5qbEUxNlZaVGpid3I5Z25sQTJzV1ZlSVpGUTdfVG9rZW46UHhGZGJVNFI2b25hWDl4TmlsS2NoaVI2bjJpXzE3MjE4Mzk5Nzc6MTcyMTg0MzU3N19WNA)

针对 HTTP **协议**，我们可以这么理解。

7. _「协议」_
    

HTTP 是一个用在计算机世界里的**协议**。它使用计算机能够理解的语言确立了一种计算机之间交流通信的规范（**两个以上的参与者**），以及相关的各种控制和错误处理方式（**行为约定和规范**）。

8. _「传输」_
    

HTTP 协议是一个**双向协议**。

针对**传输**，我们可以进一步理解了 HTTP。

HTTP 是一个在计算机世界里专门用来在**两点之间传输数据**的约定和规范。

9. _「超文本」_
    

HTTP 传输的内容是「超文本」。

理解「超文本」，它就是**超越了普通文本的文本**，它是文字、图片、视频等的混合体，最关键有超链接，能从一个超文本跳转到另外一个超文本。

**HTTP 是一个在计算机世界里专门在「两点」之间「传输」文字、图片、音频、视频等「超文本」数据的「约定和规范」。**

> HTTP是用于从互联网服务器传输超文本到本地浏览器的协议，这个说法是错误的，因为HTTP也可以服务于【服务器<--->服务器】，所有采用**两点之间**的描述比较准确

### **2.HTTP常见的状态码**

![](https://rt5bap83jl.feishu.cn/space/api/box/stream/download/asynccode/?code=NzMzNjU4MzA0ZWM3ZGY0ZWRjM2MzOWQyMzA1NmIyMjJfN01YaTBhejQ1RVlOMFdWcWphQXNXaHNLYUhGekNOWFdfVG9rZW46WFRQcGJWUWdBb1VYdVp4YmM2ZWNWdmd0bnJjXzE3MjE4Mzk5Nzc6MTcyMTg0MzU3N19WNA)

`1xx` 类状态码属于**提示信息**，是协议处理中的一种中间状态，实际用到的比较少。

`2xx` 类状态码表示服务器**成功**处理了客户端的请求，也是我们最愿意看到的状态。

- 「**200 OK**」是最常见的成功状态码，表示一切正常。如果是非 `HEAD` 请求，服务器返回的响应头都会有 body 数据。
    
- 「**204 No Content**」也是常见的成功状态码，与 200 OK 基本相同，但响应头没有 body 数据。
    
- 「**206 Partial Content**」是应用于 HTTP 分块下载或断点续传，表示响应返回的 body 数据并不是资源的全部，而是其中的一部分，也是服务器处理成功的状态。
    

`3xx` 类状态码表示客户端请求的资源发生了变动，需要客户端用新的 URL 重新发送请求获取资源，也就是**重定向**。

- 「**301 Moved Permanently**」表示永久重定向，说明请求的资源已经不存在了，需改用新的 URL 再次访问。
    
- 「**302 Found**」表示临时重定向，说明请求的资源还在，但暂时需要用另一个 URL 来访问。
    

301 和 302 都会在响应头里使用字段 `Location`，指明后续要跳转的 URL，浏览器会自动重定向新的 URL。

- 「**304 Not Modified**」不具有跳转的含义，表示资源未修改，重定向已存在的缓冲文件，也称缓存重定向，也就是告诉客户端可以继续使用缓存资源，用于缓存控制。
    

`4xx` 类状态码表示客户端发送的**报文有误**，服务器无法处理，也就是错误码的含义。

- 「**400 Bad Request**」表示客户端请求的报文有错误，但只是个笼统的错误。
    
- 「**403 Forbidden**」表示服务器禁止访问资源，并不是客户端的请求出错。
    
- 「**404 Not Found**」表示请求的资源在服务器上不存在或未找到，所以无法提供给客户端。
    

`5xx` 类状态码表示客户端请求报文正确，但是**服务器处理时内部发生了错误**，属于服务器端的错误码。

- 「**500 Internal Server Error**」与 400 类型，是个笼统通用的错误码，服务器发生了什么错误，我们并不知道。
    
- 「**501 Not Implemented**」表示客户端请求的功能还不支持，类似“即将开业，敬请期待”的意思。
    
- 「**502 Bad Gateway**」通常是服务器作为网关或代理时返回的错误码，表示服务器自身工作正常，访问后端服务器发生了错误。
    
- 「**503 Service Unavailable**」表示服务器当前很忙，暂时无法响应客户端，类似“网络服务正忙，请稍后重试”的意思。
    

### **3.HTTP 常见字段有哪些？**