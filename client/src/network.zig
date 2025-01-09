const std = @import("std");
const net = std.net;
const gs = @import("gamestate.zig");

const bufsize: usize = 1024;

pub fn connect(host: []const u8, port: comptime_int) !net.Stream {
    const peer = try net.Address.parseIp4(host, port);
    const stream = try net.tcpConnectToAddress(peer);
    return stream;
}

// TODO Placeholder, this will carry some additional logic going forward
pub fn handshake(stream: *const net.Stream, buffer: *[36]u8) !void {
    _ = try stream.reader().read(buffer);
}

pub fn receiveUpdate(stream: *const net.Stream, allocator: std.mem.Allocator) !gs.GameState {
    var buffer: [bufsize]u8 = undefined;

    _ = try stream.reader().read(&buffer);

    return gs.decode(&buffer, allocator);
}

pub fn sendUpdate(stream: *const net.Stream, buffer: []const u8) !void {
    try stream.writer().writeAll(buffer);
}
