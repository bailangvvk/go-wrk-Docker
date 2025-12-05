# go-wrk Docker 镜像

## 说明

这是一个基于 go-wrk 性能测试工具的 Docker 镜像。

### 基本用法

```
./go-wrk -c 2048 -d 10 http://localhost:8080/plaintext
```

### Docker 用法

```
docker run \
--name go-wrk \
--rm \
--network host \
bailangvvking/go-wrk \
-c 2048 -d 10 http://127.0.0.1:80
```

## 命令行选项

```
用法: go-wrk <选项> <URL>
   选项:
    -H       添加到每个请求的头部（可以定义多个 -H 标志）（默认值：空）
    -M       HTTP 方法（默认值：GET）
    -T       套接字/请求超时时间（毫秒）（默认值：1000）
    -body    请求体字符串或 @文件名（默认值：空）
    -c       使用的 goroutine 数量（并发连接数）（默认值：10）
    -ca      用于验证对等方的 CA 文件（SSL/TLS）（默认值：空）
    -cert    用于验证对等方的 CA 证书文件（SSL/TLS）（默认值：空）
    -d       测试持续时间（秒）（默认值：10）
    -f       回放文件名（默认值：空）
    -help    打印帮助信息（默认值：false）
    -host    主机头（默认值：空）
    -http    使用 HTTP/2（默认值：true）
    -key     私钥文件名（SSL/TLS）（默认值：空）
    -no-c    禁用压缩 - 防止发送 "Accept-Encoding: gzip" 头部（默认值：false）
    -no-ka   禁用 KeepAlive - 防止在不同 HTTP 请求之间重用 TCP 连接（默认值：false）
    -no-vr   跳过验证服务器的 SSL 证书（默认值：false）
    -redir   允许重定向（默认值：false）
    -v       打印版本详细信息（默认值：false）
