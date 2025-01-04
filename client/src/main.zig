//! Dogfight! client side
//!
//! Connects to the gameserver running at port 6699 and receive the gamestate
//! with its own positioned ship
const std = @import("std");
const net = std.net;
const gamestate = @import("gamestate.zig");

const buf_size: usize = 1024;
const server_port: u16 = 6699;

fn connectToServer(port: u16) !void {
    const peer = try net.Address.parseIp4("127.0.0.1", port);
    // Connect to peer
    const stream = try net.tcpConnectToAddress(peer);
    defer stream.close();
    std.debug.print("Connecting to {}\n", .{peer});

    var buffer: [buf_size]u8 = undefined;
    _ = try stream.reader().readAll(&buffer);

    // Print the response
    const game_state = try gamestate.decode(&buffer);

    const stdout = std.io.getStdOut().writer();
    try game_state.print(stdout);
}

pub fn main() !void {
    // Prints to stderr (it's a shortcut based on `std.io.getStdErr()`)
    std.debug.print("Connecting to game server {}\n", .{server_port});
    try connectToServer(server_port);
}
