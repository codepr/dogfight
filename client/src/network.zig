const std = @import("std");
const net = std.net;
const gs = @import("gamestate.zig");

const bufsize: usize = 2048;

pub fn connect(host: []const u8, port: comptime_int) !net.Stream {
    const peer = try net.Address.parseIp4(host, port);
    const stream = try net.tcpConnectToAddress(peer);
    return stream;
}

pub fn receiveUpdate(stream: *const net.Stream, allocator: std.mem.Allocator) !gs.GameState {
    var buffer: [bufsize]u8 = undefined;

    _ = try stream.reader().readAll(&buffer);
    return gs.decode(&buffer, allocator);
}

// pub fn sendUpdate(conn: *net.Connection, buffer: []u8) !void {
// }
