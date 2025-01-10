//! Dogfight! client side
//!
//! Connects to the gameserver running at port 6699 and receive the gamestate
//! with its own positioned ship
const std = @import("std");
const net = @import("network.zig");
const render = @import("render.zig");
const input = @import("input.zig");
const event = @import("event.zig");
const gs = @import("gamestate.zig");

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

    // Read player ID
    var player_id: [36]u8 = undefined;
    try net.handshake(&stream, &player_id);
    std.debug.print("Player ID: {s}\n", .{player_id});

    var renderer = try render.Renderer.init(screen_width, screen_height, target_fps, allocator);
    defer renderer.deinit();

    // Main game loop
    // Detect window close button or ESC key
    while (render.windowIsOpen()) {
        // Receive the game state from the server
        const gamestate = try net.receiveUpdate(&stream, allocator);
        // Log it to console for debug
        // const stdout = std.io.getStdOut().writer();
        // try gamestate.print(stdout);
        // Draw game state
        renderer.drawGameState(&gamestate);
        //----------------------------------------------------------------------------------
        // Capture any input
        if (input.input()) |input_event| {
            const game_event = switch (input_event) {
                .move_up => event.Event{ .move = event.Event.MoveEvent{ .player_id = player_id, .direction = gs.Direction.up } },
                .move_down => event.Event{ .move = event.Event.MoveEvent{ .player_id = player_id, .direction = gs.Direction.down } },
                .move_left => event.Event{ .move = event.Event.MoveEvent{ .player_id = player_id, .direction = gs.Direction.left } },
                .move_right => event.Event{ .move = event.Event.MoveEvent{ .player_id = player_id, .direction = gs.Direction.right } },
                .shoot => event.Event{ .shoot = player_id },
            };
            const buffer = try event.encode(game_event, allocator);
            try net.sendUpdate(&stream, buffer);
        }

        render.text("Moved", 190, 200, 20);
    }
}
