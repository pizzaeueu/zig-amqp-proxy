const std = @import("std");

const proxy_port: u16 = 1234;
const amqp_broker_port: u16 = 5672;

pub fn main() !void {
    const amqp_host: []const u8 = std.posix.getenv("AMQP_HOST") orelse "127.0.0.1";
    var gpa_instance = std.heap.GeneralPurposeAllocator(.{}).init;
    const allocator = gpa_instance.allocator();

    const proxy_address = std.net.Address.initIp4(.{ 0, 0, 0, 0 }, proxy_port);
    var proxy_server = try std.net.Address.listen(proxy_address, .{});
    defer proxy_server.deinit();

    std.log.info("Server started on {} port", .{proxy_port});
    std.log.info("AMQP host is {s}", .{amqp_host});

    var connection_counter: u64 = 0;
    while (true) {
        const proxy_client = try proxy_server.accept();
        connection_counter += 1;
        // TODO unsafe: we are spawning a thread for each connection and not joining them
        _ = try std.Thread.spawn(.{}, handle_connection, .{ allocator, proxy_client, connection_counter, amqp_host });
    }
    std.log.info("Server closed", .{});
}

fn handle_connection(allocator: std.mem.Allocator, proxy_client: anytype, connection_id: anytype, amqp_host: anytype) !void {
    defer proxy_client.stream.close();
    const connection_id_label = try std.fmt.allocPrint(allocator, "connection id = {d}", .{connection_id});

    const proxy_client_reader = proxy_client.stream.reader();
    const proxy_client_writer = proxy_client.stream.writer();

    std.log.info("Accepted new connection {s}", .{connection_id_label});

    try run_bidirect_tunnel(allocator, proxy_client_reader, proxy_client_writer, connection_id_label, amqp_host);

    std.log.info("Connection closed {s}", .{connection_id_label});
}

pub fn run_bidirect_tunnel(allocator: std.mem.Allocator, proxy_client_reader: anytype, proxy_client_writer: anytype, connection_id_label: anytype, amqp_host: anytype) !void {
    var amqp_broker_stream = try std.net.tcpConnectToHost(allocator, amqp_host, amqp_broker_port);
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
