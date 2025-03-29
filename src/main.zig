const std = @import("std");

pub fn main() !void {
    var gpa_instance = std.heap.GeneralPurposeAllocator(.{}).init;
    const allocator = gpa_instance.allocator();

    const proxy_address = try std.net.Address.parseIp("127.0.0.1", 5672);
    var server = try std.net.Address.listen(proxy_address, .{});
    defer server.deinit();

    var client = try server.accept();
    defer client.stream.close();

    const client_reader = client.stream.reader();
    //const client_writer = client.stream.writer();

    try start_handshake_with_rabbit(client_reader, allocator);
}

pub fn echo_response(client_reader: anytype, client_writer: anytype, allocator: std.mem.Allocator) !void {
    while (true) {
        const msg = try client_reader.readUntilDelimiterOrEofAlloc(allocator, '\n', 65536) orelse break;
        defer allocator.free(msg);

        std.log.info("Recieved message From Client: \"{}\"", .{std.zig.fmtEscapes(msg)});

        try client_writer.writeAll(msg);
    }
}

pub fn start_handshake_with_rabbit(client_reader: anytype, allocator: std.mem.Allocator) !void {
    var rabbit_stream = try std.net.tcpConnectToHost(allocator, "127.0.0.1", 5671);
    defer rabbit_stream.close();
    const rabbit_writer = rabbit_stream.writer();

    var client_buf: [1024]u8 = undefined;

    const n = try client_reader.read(&client_buf);
    const slice = client_buf[0..n];
    std.log.info("Slice:{s} ", .{slice});
    rabbit_writer.writeAll(slice) catch |err| {
        std.log.err("Failed to send to Rabbit", .{});
        return err;
    };
    std.log.info("Connection closed", .{});
}
