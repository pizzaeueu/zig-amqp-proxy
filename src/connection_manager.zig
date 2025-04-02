const std = @import("std");

pub fn handle_connection(allocator: std.mem.Allocator, proxy_client: anytype, connection_id: anytype, amqp_host: anytype, amqp_broker_port: anytype) void {
    try_handle_connection(allocator, proxy_client, connection_id, amqp_host, amqp_broker_port) catch |err| {
        std.log.err("Failed to start connection id {d} - {}", .{ connection_id, err });
    };
}

fn try_handle_connection(allocator: std.mem.Allocator, proxy_client: anytype, connection_id: anytype, amqp_host: anytype, amqp_broker_port: anytype) !void {
    defer proxy_client.stream.close();
    const connection_id_label = try std.fmt.allocPrint(allocator, "connection id = {d}", .{connection_id});

    const proxy_client_reader = proxy_client.stream.reader();
    const proxy_client_writer = proxy_client.stream.writer();

    std.log.info("Accepted new connection {s}", .{connection_id_label});

    try run_bidirect_tunnel(allocator, proxy_client_reader, proxy_client_writer, connection_id_label, amqp_host, amqp_broker_port);

    std.log.info("Connection closed {s}", .{connection_id_label});
}

fn run_bidirect_tunnel(allocator: std.mem.Allocator, proxy_client_reader: anytype, proxy_client_writer: anytype, connection_id_label: anytype, amqp_host: anytype, amqp_broker_port: anytype) !void {
    // We need to create new tcp stream for each broker connection due to AMQP protocol internals
    // Alternatively, we could use a single connection and block to single client at time which is even worse
    // As a better solution: multiplex AMQP frames (out of scope for L4 proxy?)
    var amqp_broker_stream = std.net.tcpConnectToHost(allocator, amqp_host, amqp_broker_port) catch |err| {
        std.log.err("Failed to connect to AMQP broker: {}", .{err});
        return;
    };
    defer amqp_broker_stream.close();

    const amqp_broker_reader = amqp_broker_stream.reader();
    const amqp_broker_writer = amqp_broker_stream.writer();

    const client_to_broker_connection_lable = try std.fmt.allocPrint(allocator, "client → amqp broker {s}", .{connection_id_label});
    const forward = try std.Thread.spawn(.{}, pass_stream, .{ proxy_client_reader, amqp_broker_writer, client_to_broker_connection_lable });

    try pass_stream(amqp_broker_reader, proxy_client_writer, client_to_broker_connection_lable);

    forward.join();
}

fn pass_stream(reader: anytype, writer: anytype, label: []const u8) !void {
    var buf: [1024]u8 = undefined;

    while (true) {
        const n = try reader.read(&buf);
        if (n == 0) break;

        writer.writeAll(buf[0..n]) catch |err| {
            std.log.err("[{s}] error forwarding: {}", .{ label, err });
            break;
        };
        std.log.info("[{s}] forwarded {d} bytes", .{ label, n });
    }
}
