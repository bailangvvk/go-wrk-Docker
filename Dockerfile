# Hugo Static Compilation Docker Build with BusyBox
# 使用 busybox:musl 作为基础镜像，提供基本shell环境

# 构建阶段 - 使用完整的构建环境
FROM golang:1.21-alpine AS builder
# FROM golang:1.25-alpine AS builder

WORKDIR /app

# 安装构建依赖（包括C++编译器和strip工具）
RUN set -eux &&apk add --no-cache --virtual .build-deps \
    gcc \
    g++ \
    musl-dev \
    git \
    build-base \
    # 包含strip命令
    binutils \
    # 直接下载并构建 go-wrk（无需本地源代码）
    && git clone --depth 1 https://github.com/tsliwowicz/go-wrk . \
    # 构建静态二进制文件
    && CGO_ENABLED=1 go build \
    -tags extended,netgo,osusergo \
    -ldflags="-s -w -extldflags -static" \
    -o go-wrk \
    # 验证二进制文件是否存在
    # && test -f go-wrk && echo "Binary built successfully" || (echo "Binary not found" && exit 1) \
    && du -h go-wrk \
    # 使用strip进一步减小二进制文件大小
    && strip --strip-all go-wrk \
    && du -h go-wrk \
    # 验证二进制文件是否为静态链接
    # && ldd go-wrk 2>&1 | grep -q "not a dynamic executable" \
    # && echo "Static binary confirmed" || echo "Not a static binary" \
    # 显示优化后的文件大小
    # && ls -lh go-wrk && echo "Binary size after stripping: $(stat -c%s go-wrk) bytes" \
    # 清理构建依赖
    && apk del --purge .build-deps \
    && rm -rf /var/cache/apk/*

# 运行时阶段 - 使用busybox:musl（极小的基础镜像，包含基本shell）
FROM busybox:musl
# FROM alpine:latest

# 复制CA证书（用于HTTPS请求）
# COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/

# 复制经过strip优化的go-wrk二进制文件到系统路径
COPY --from=builder /app/go-wrk /usr/local/bin/go-wrk

# 创建非root用户（增强安全性）
RUN adduser -D -u 1000 gowrk

# 设置工作目录
WORKDIR /app

# 切换到非root用户
USER gowrk

# Go 运行时优化：垃圾回收器（GC）调优
# GOGC 环境变量控制GC的频率。默认值是100，表示当堆大小翻倍时触发GC。
# 在内存充足的环境中，增大此值（例如 GOGC=200）可以减少GC的运行频率，
# 从而可能提升程序性能，但代价是消耗更多的内存。
# 您可以在 `docker run` 时通过 `-e GOGC=200` 来覆盖此默认设置。
ENV GOGC=100

# 设置入口点
ENTRYPOINT ["go-wrk"]
