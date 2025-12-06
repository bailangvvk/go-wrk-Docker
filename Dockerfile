# Hugo Static Compilation Docker Build with BusyBox
# 使用 busybox:musl 作为基础镜像，提供基本shell环境

# 构建阶段 - 使用完整的构建环境
# FROM golang:1.21-alpine AS builder
FROM golang:1.25-alpine AS builder

WORKDIR /app

# 安装最小构建依赖（使用--no-scripts避免busybox触发器问题）
# 注意：由于是多阶段构建，我们不在构建阶段清理依赖，以避免触发器错误
RUN set -eux && apk add --no-cache --no-scripts --virtual .build-deps \
    gcc \
    musl-dev \
    git \
    # 包含strip命令
    binutils \
    upx \
    # 直接下载并构建 go-wrk（无需本地源代码）
    && git clone --depth 1 https://github.com/tsliwowicz/go-wrk . \
    # 构建静态二进制文件
    # 使用CGO_ENABLED=1配合静态链接，可能生成更小的二进制文件
    && CGO_ENABLED=1 go build \
    -trimpath \
    -tags extended,netgo,osusergo \
    # 确保完全静态链接，减小最终二进制大小
    -ldflags="-s -w -extldflags=-static" \
    -o go-wrk \
    # 显示构建后的文件大小（字节）
    && echo "Binary size after build:" \
    && du -b go-wrk \
    # 使用strip进一步减小二进制文件大小
    && strip --strip-all go-wrk \
    && echo "Binary size after stripping:" \
    && du -b go-wrk \
    # 使用UPX压缩（显著减小文件大小，运行时性能无实质影响）
    && upx --best --lzma go-wrk \
    && echo "Binary size after UPX:" \
    && du -b go-wrk
    # 注意：这里故意不清理构建依赖，因为是多阶段构建，且清理会触发busybox触发器错误
    # 最终镜像只复制二进制文件，构建阶段的中间层不会影响最终镜像大小

# 运行时阶段 - 使用busybox:musl（极小的基础镜像，包含基本shell）
# FROM busybox:musl
# FROM alpine:latest
FROM scratch

# 复制CA证书（用于HTTPS请求）
# COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/

# 复制go-wrk二进制文件
COPY --from=builder /app/go-wrk /go-wrk

# 创建非root用户（增强安全性）
# RUN adduser -D -u 1000 gowrk

# 设置工作目录
# WORKDIR /app

# 切换到非root用户
# USER gowrk

# Go 运行时优化：垃圾回收器（GC）调优
# GOGC 环境变量控制GC的频率。默认值是100，表示当堆大小翻倍时触发GC。
# 在内存充足的环境中，增大此值（例如 GOGC=200）可以减少GC的运行频率，
# 从而可能提升程序性能，但代价是消耗更多的内存。
# 您可以在 `docker run` 时通过 `-e GOGC=200` 来覆盖此默认设置。
# ENV GOGC=100

# 设置入口点
ENTRYPOINT ["/go-wrk"]
