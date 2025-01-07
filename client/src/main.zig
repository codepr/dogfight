//! Dogfight! client side
//!
//! Connects to the gameserver running at port 6699 and receive the gamestate
//! with its own positioned ship
const std = @import("std");
const rl = @import("raylib");
const net = @import("network.zig");
const render = @import("render.zig");

const server_port = 6699;
const screen_width = 800;
const screen_height = 600;
const target_fps = 60;

pub fn main() anyerror!void {
    std.debug.print("Connecting to game server {}\n", .{server_port});

    const allocator = std.heap.page_allocator;
    // Connect to peer
    const stream = try net.connect("127.0.0.1", server_port);
    defer stream.close();

    render.init(screen_width, screen_height, target_fps);
    defer render.shutdown();

    // Main game loop
    // Detect window close button or ESC key
    while (render.windowIsOpen()) {
        // Receive the game state from the server
        const gamestate = try net.receiveUpdate(&stream, allocator);
        // Log it to console for debug
        const stdout = std.io.getStdOut().writer();
        try gamestate.print(stdout);
        // Draw game state
        render.drawGameState(&gamestate);
        render.text("Congrats! You created your first window!", 190, 200, 20);
        //----------------------------------------------------------------------------------
    }
}
