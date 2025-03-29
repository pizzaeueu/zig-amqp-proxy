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
- I implemented a simple chain Client -> Proxy -> AMPQ server, it starts the handshake process, but the idea is to implement a tunnel, which is protocol agnostic

_btw was pretty fun to find Zig compile time duck typing_


===
- `zig build run`
- `zig build test`
- `zig fmt`
