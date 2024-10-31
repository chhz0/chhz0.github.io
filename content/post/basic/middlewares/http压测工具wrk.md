--- 
title:  "[wrk] http压测工具"
subtitle: "用以测试http服务的吞吐性能"
tags:  ["wrk","http"]
date:  "2024-10-31"
---

```Go
使用方法: wrk <选项> <被测HTTP服务的URL>                           

  Options:                                           
    -c, --connections <N>  跟服务器建立并保持的TCP连接数量 
    -d, --duration    <T>  压测时间          
    -t, --threads     <N>  使用多少个线程进行压测，压测时，是有一个主线程来控制我们设置的n个子线程间调度  
                                                    
    -s, --script      <S>  指定Lua脚本路径      
    -H, --header      <H>  为每一个HTTP请求添加HTTP头     
        --latency          在压测结束后，打印延迟统计信息  
        --timeout     <T>  超时时间    
    -v, --version          打印正在使用的wrk的详细版本信                                              

  <N>代表数字参数，支持国际单位 (1k, 1M, 1G)
  <T>代表时间参数，支持时间单位 (2s, 2m, 2h)
```