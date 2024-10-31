## Bind to a port

使用`net` 开启一个TCP服务，监听端口6379
```go
func main() {
    // You can use print statements as follows for debugging, they'll be visible when running tests.

    fmt.Println("Logs from your program will appear here!")
    // Uncomment this block to pass the first stage

    l, err := net.Listen("tcp", "0.0.0.0:6379")
    if err != nil {
        fmt.Println("Failed to bind to port 6379")
        os.Exit(1)
    }
    _, err = l.Accept()
    if err != nil {
        fmt.Println("Error accepting connection: ", err.Error())
        os.Exit(1)
    }
}
```

Redis 客户端和服务器使用 TCP 相互通信。

## Respond to PING
