FROM debian:bullseye-slim

WORKDIR /app

RUN apt-get update && apt-get install -y \
    curl \
    xz-utils \
    build-essential \
    git \
    && rm -rf /var/lib/apt/lists/*

RUN curl -sSL https://ziglang.org/download/0.14.0/zig-linux-x86_64-0.14.0.tar.xz -o zig.tar.xz \
    && mkdir -p /usr/local/zig \
    && tar -xf zig.tar.xz --strip-components=1 -C /usr/local/zig \
    && rm zig.tar.xz \
    && ln -s /usr/local/zig/zig /usr/local/bin/zig

COPY src/ /app/src/
COPY build.zig /app/build.zig

RUN zig build
CMD ["./zig-out/bin/zig_proxy"]
