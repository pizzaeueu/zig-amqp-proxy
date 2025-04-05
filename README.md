## Local Run
There is a docker compose that run broker, proxy server and two producers that send messages to the broker in parallel.
- run `docker compose up` (first run ~1m)
- open [http://localhost:15672/#/queues/%2F/hello](http://localhost:15672/#/queues/%2F/hello)
- Use `admin:admin` to login
- There is a graph with info about messages sent to the queue
___
- `zig build run` -- Run the project
- `zig build test --summary all` -- Run tests
- `zig fmt` -- Format code
