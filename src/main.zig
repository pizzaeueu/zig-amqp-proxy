const std = @import("std");
const connection_manager = @import("connection_manager.zig");

const proxy_port: u16 = 1234;
const amqp_broker_port: u16 = 5672;

pub fn main() !void {
    const amqp_host: []const u8 = std.posix.getenv("AMQP_HOST") orelse "127.0.0.1";
    var gpa_instance = std.heap.GeneralPurposeAllocator(.{}).init;
    const allocator = gpa_instance.allocator();

    const proxy_address = std.net.Address.initIp4(.{ 0, 0, 0, 0 }, proxy_port);
    var proxy_server = std.net.Address.listen(proxy_address, .{}) catch |err| {
        std.log.err("Failed to start server: {}", .{err});
        return;
    };
    defer proxy_server.deinit();

    std.log.info("Server started on {} port", .{proxy_port});
    std.log.info("AMQP host is {s}", .{amqp_host});

    var connection_counter: u64 = 0;
    while (true) {
        const proxy_client = try proxy_server.accept();
        connection_counter += 1;
        // TODO unsafe: we are spawning a thread for each connection and not joining them
        _ = std.Thread.spawn(.{}, connection_manager.handle_connection, .{ allocator, proxy_client, connection_counter, amqp_host, amqp_broker_port }) catch |err| {
            std.log.err("Failed to start connection id {d} - {}", .{ connection_counter, err });
        };
    }
    std.log.info("Server closed", .{});
}
