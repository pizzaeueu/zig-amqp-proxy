## Local Run
- run `docker compose up` (first run ~1m)
- open [http://localhost:15672/#/queues/%2F/hello](http://localhost:15672/#/queues/%2F/hello)
- Use `admin:admin` to login
- There is a graph with info about messages sent to the queue

---
## First Impression on ZIG
- Didn't use the language without GC for a while, really excited to give a try
- Build tool / code formatter is a part of the language is quite interesting
- Need to understand test philosophy

## 2025-03-28
- Generated simple hello world using `zig init`
- My way to learn things is: cycle of practice and theory with gradual dive step by step, so I want to start with something as a first step
- Found an artical 'bout low level tcp implementation on zig, so will follow it

## 2025-03-29
- I was playing around with low-level tcp server implementation and found more high-level during research of the std lib, so I decided to use it
- The echo server was pretty straightforward to implement
- I implemented a simple chain Client -> Proxy -> AMQP server, it starts the handshake process, but the idea is to implement a tunnel, which is protocol agnostic

_btw was pretty fun to find Zig compile time duck typing_


## 2025-03-30
- Finished with simple tunnel, it works with happy path and support single client
- Spent some time to run "client -> proxy" and "proxy -> amqp broker" in parallel. Actually thread API looks familiar on the first glance. Like a java's low-level abstractions.
- Dove deep into Zig's memory management to understand how it works with the heap, stack, and rodata. So far, it looks relatively safe, so I'm waiting for my first memory leak 😄

## 2025-03-31
- [Discovery of the day](https://github.com/ziglang/docker-zig): _Zig makes Docker irrelevant. You probably do not need a Docker image to build your Zig application, and you definitely do not need this one._
- I've stacked a bit with exposing the proxy to other containers (need to double-check `std.net.parseIp(host, proxy_port)` docs )


===
- `zig build run`
- `zig build test`
- `zig fmt`
