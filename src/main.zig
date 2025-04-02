const std = @import("std");
const connection_manager = @import("connection_manager.zig");
const getenv = std.posix.getenv;
const Address = std.net.Address;
const log = std.log;
const Addr = connection_manager.Addr;
const Thread = std.Thread;

const proxy_port: u16 = 1234;
const amqp_broker_port: u16 = 5672;

pub fn main() !void {
    const amqp_host: []const u8 = getenv("AMQP_HOST") orelse "127.0.0.1";
    var gpa_instance = std.heap.GeneralPurposeAllocator(.{}).init;
    const allocator = gpa_instance.allocator();

    const proxy_address = Address.initIp4(.{ 0, 0, 0, 0 }, proxy_port);
    var proxy_server = Address.listen(proxy_address, .{}) catch |err| {
        log.err("Failed to start server: {}", .{err});
        return;
    };
    defer proxy_server.deinit();

    log.info("Server started on {} port", .{proxy_port});
    log.info("AMQP host is {s}", .{amqp_host});

    const amqp_broker_addr = Addr{ .host = amqp_host, .port = amqp_broker_port };
    var connection_counter: u64 = 0;
    while (true) {
        const proxy_client = try proxy_server.accept();
        connection_counter += 1;
        // TODO unsafe: we are spawning a thread for each connection and not joining them
        _ = Thread.spawn(.{}, connection_manager.handle_connection, .{ allocator, proxy_client, connection_counter, amqp_broker_addr }) catch |err| {
            log.err("Failed to start connection id {d} - {}", .{ connection_counter, err });
        };
    }
    log.info("Server closed", .{});
}
