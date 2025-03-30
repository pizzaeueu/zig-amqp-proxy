const std = @import("std");

const host: []const u8 = "127.0.0.1";
const proxy_port: u16 = 5672;
const amqp_broker_port: u16 = 5671;

pub fn main() !void {
    var gpa_instance = std.heap.GeneralPurposeAllocator(.{}).init;
    const allocator = gpa_instance.allocator();

    const proxy_address = try std.net.Address.parseIp(host, proxy_port);
    var proxy_server = try std.net.Address.listen(proxy_address, .{});
    defer proxy_server.deinit();

    var proxy_client = try proxy_server.accept();
    defer proxy_client.stream.close();

    const proxy_client_reader = proxy_client.stream.reader();
    const proxy_client_writer = proxy_client.stream.writer();

    try run_bidirect_tunnel(allocator, proxy_client_reader, proxy_client_writer);
}

pub fn run_bidirect_tunnel(allocator: std.mem.Allocator, proxy_client_reader: anytype, proxy_client_writer: anytype) !void {
    var amqp_broker_stream = try std.net.tcpConnectToHost(allocator, host, amqp_broker_port);
    defer amqp_broker_stream.close();

    const amqp_broker_reader = amqp_broker_stream.reader();
    const amqp_broker_writer = amqp_broker_stream.writer();

    const forward = try std.Thread.spawn(.{}, pass_stream, .{
        proxy_client_reader,
        amqp_broker_writer,
        "client → amqp broker",
    });

    try pass_stream(amqp_broker_reader, proxy_client_writer, "amqp broker → client");

    forward.join();
}

fn pass_stream(reader: anytype, writer: anytype, label: []const u8) !void {
    var buf: [1024]u8 = undefined;

    while (true) {
        const n = try reader.read(&buf);
        if (n == 0) break;

        try writer.writeAll(buf[0..n]);
        std.log.info("[{s}] forwarded {d} bytes", .{ label, n });
    }
}
