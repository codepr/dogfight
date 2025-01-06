//! GameState Utilities Module
//!
//! This module defines the core data structures and utility functions for
//! representing the game state in a simple game. It includes structs for
//! players, bullets, power-ups, and the overall game state. The module also
//! provides functionality to print these structures in a human-readable
//! format, which can be useful for debugging or logging.
//!
//! The key components of this module are as follows:
//!
//! - **Vector2D**:
//!     A struct representing a 2D coordinate with x and y components.
//!
//! - **Direction**:
//!     An enum representing the four possible directions of
//!     movement: Up, Down, Left, and Right.
//!
//! - **Bullet**:
//!     A struct representing a bullet fired by a player, including its
//!     position, direction, and active state.
//!
//! - **Player**:
//!     A struct representing a player in the game, including health,
//!     direction, status, and the list of bullets they have fired.
//!
//! - **PowerUpKind**:
//!     An enum representing different types of power-ups that can be
//!     collected by players, including health and ammo boosts.
//!
//! - **PowerUp**:
//!     A struct representing a power-up, including its coordinates and type.
//!
//! - **GameState**:
//!     A struct representing the entire game state, which includes all players,
//!     the current active player, and the active power-up.
//!
//! Additionally, each of these structs and enums has a `print` function that
//! prints their respective data in a human-readable format. This is useful for
//! logging or displaying the game state in a simple text format.
//!
//!
//! Example usage:
//!
//! To print the game state, one would create a `GameState` object and call its
//! `print` function:
//!
//! ```
//! var game_state = GameState{
//!     .players = players,
//!     .active_players = 3,
//!     .player_index = 0,
//!     .power_up = power_up
//! };
//! try game_state.print(std.debug.out);
//! ```
//!
//! This module is primarily used for representing and debugging the game state
//! during development.

// TODO bullet fire
// TODO Using fixed sizes for the time being, move to dynamic sizing

const std = @import("std");
const net = std.net;
const testing = std.testing;

const max_players: usize = 5;
const max_bullets: usize = 5;

const Vector2D = struct {
    x: i32,
    y: i32,

    pub fn print(self: Vector2D, writer: anytype) !void {
        try writer.print("({d}, {d})", .{ self.x, self.y });
    }
};

const Direction = enum {
    Up,
    Down,
    Left,
    Right,

    pub fn print(self: Direction, writer: anytype) !void {
        const dir_names = [_][]const u8{
            "Up", "Down", "Left", "Right",
        };
        try writer.print("{s}", .{dir_names[@intFromEnum(self)]});
    }
};

const Bullet = struct {
    coordinates: Vector2D,
    direction: Direction,
    active: bool,

    pub fn print(self: Bullet, writer: anytype) !void {
        try writer.print("Coordinates: ", .{});
        try self.coordinates.print(writer);
        try writer.print(" Direction: ", .{});
        try self.direction.print(writer);
        try writer.print(" Active: {s}\n", .{if (self.active) "true" else "false"});
    }
};
const Player = struct {
    coordinates: Vector2D,
    hp: i32,
    direction: Direction,
    alive: bool,
    bullets: [max_bullets]Bullet,

    pub fn print(self: Player, writer: anytype) !void {
        try writer.print("Coordinates: ", .{});
        try self.coordinates.print(writer);
        try writer.print(" HP: {d}\n", .{self.hp});
        try writer.print("Direction: ", .{});
        try self.direction.print(writer);
        try writer.print(" Alive: {s}\n", .{if (self.alive) "true" else "false"});

        try writer.print("Bullets:\n", .{});
        for (self.bullets) |bullet| {
            try bullet.print(writer);
        }
    }
};

const PowerUpKind = enum {
    None,
    HpPlusOne,
    HpPlusThree,
    AmmoPlusOne,

    pub fn print(self: PowerUpKind, writer: anytype) !void {
        const kind_names = [_][]const u8{
            "None", "HpPlusOne", "HpPlusThree", "AmmoPlusOne",
        };
        try writer.print("{s}", .{kind_names[@intFromEnum(self)]});
    }
};

const PowerUp = struct {
    coordinates: Vector2D,
    kind: PowerUpKind,

    pub fn print(self: PowerUp, writer: anytype) !void {
        try writer.print("Coordinates: ", .{});
        try self.coordinates.print(writer);
        try writer.print(" Kind: ", .{});
        try self.kind.print(writer);
        try writer.print("\n", .{});
    }
};

const GameState = struct {
    players: [max_players]Player,
    active_players: usize,
    player_index: usize,
    power_up: PowerUp,

    pub fn print(self: GameState, writer: anytype) !void {
        try writer.print("GameState:\n", .{});
        try writer.print("Active Players: {d}\n", .{self.active_players});
        try writer.print("Player Index: {d}\n", .{self.player_index});
        try writer.print("PowerUp: ", .{});
        try self.power_up.print(writer);

        for (0.., self.players) |index, player| {
            try writer.print("Player {d}:\n", .{index});
            try player.print(writer);
        }
    }
};

// Serialization

pub fn encode(game_state: GameState, allocator: std.mem.Allocator) ![]u8 {
    const total_length = @sizeOf(Player) * max_players + @sizeOf(Bullet) * max_bullets * max_players + @sizeOf(i32) * 5 + @sizeOf(u8);

    const buffer = try allocator.alloc(u8, total_length);
    errdefer allocator.free(buffer); // Ensure buffer is freed on error
    var buffered_stream = std.io.fixedBufferStream(buffer);
    var writer = buffered_stream.writer();

    try writer.writeInt(i32, total_length, .big);
    try writer.writeInt(i32, @intCast(game_state.player_index), .big);
    try writer.writeInt(i32, @intCast(game_state.active_players), .big);
    try writer.writeInt(i32, game_state.power_up.coordinates.x, .big);
    try writer.writeInt(i32, game_state.power_up.coordinates.y, .big);
    try writer.writeInt(u8, @intFromEnum(game_state.power_up.kind), .big);

    for (game_state.players) |player| {
        try writer.writeInt(i32, player.coordinates.x, .big);
        try writer.writeInt(i32, player.coordinates.y, .big);
        try writer.writeInt(i32, player.hp, .big);
        try writer.writeInt(u8, @intFromBool(player.alive), .big);
        try writer.writeInt(u8, @intFromEnum(player.direction), .big);

        for (player.bullets) |bullet| {
            try writer.writeInt(i32, bullet.coordinates.x, .big);
            try writer.writeInt(i32, bullet.coordinates.y, .big);
            try writer.writeInt(u8, @intFromBool(bullet.active), .big);
            try writer.writeInt(u8, @intFromEnum(bullet.direction), .big);
        }
    }
    return buffer;
}

pub fn decode(buffer: []const u8) !GameState {
    var buffered_stream = std.io.fixedBufferStream(buffer);
    var reader = buffered_stream.reader();

    _ = try reader.readInt(i32, .big);
    const player_index = try reader.readInt(i32, .big);
    const active_players = try reader.readInt(i32, .big);

    const power_up = PowerUp{
        .coordinates = Vector2D{
            .x = try reader.readInt(i32, .big),
            .y = try reader.readInt(i32, .big),
        },
        .kind = @enumFromInt(try reader.readInt(u8, .big)),
    };

    var players: [max_players]Player = undefined;
    for (&players) |*player| {
        player.coordinates = Vector2D{
            .x = try reader.readInt(i32, .big),
            .y = try reader.readInt(i32, .big),
        };
        player.hp = try reader.readInt(i32, .big);
        player.alive = try reader.readInt(u8, .big) != 0; // Deserialize bool as u8
        player.direction = @enumFromInt(try reader.readInt(u8, .big));

        var bullets: [max_bullets]Bullet = undefined;
        for (&bullets) |*bullet| {
            bullet.coordinates = Vector2D{
                .x = try reader.readInt(i32, .big),
                .y = try reader.readInt(i32, .big),
            };
            bullet.active = try reader.readInt(u8, .big) != 0; // Deserialize bool as u8
            bullet.direction = @enumFromInt(try reader.readInt(u8, .big));
        }
        player.bullets = bullets; // Assign bullets array
    }

    return GameState{
        .player_index = @intCast(player_index),
        .active_players = @intCast(active_players),
        .power_up = power_up,
        .players = players,
    };
}

test "serialization and deserialization work correctly" {
    const allocator = std.heap.page_allocator;

    const power_up = PowerUp{
        .coordinates = Vector2D{ .x = 10, .y = 20 },
        .kind = PowerUpKind.HpPlusOne,
    };

    const players: [max_players]Player = .{ Player{
        .coordinates = Vector2D{ .x = 1, .y = 2 },
        .hp = 100,
        .alive = true,
        .direction = Direction.Up,
        .bullets = .{
            Bullet{
                .coordinates = Vector2D{ .x = 10, .y = 20 },
                .active = true,
                .direction = Direction.Right,
            },
            Bullet{
                .coordinates = Vector2D{ .x = 20, .y = 20 },
                .active = true,
                .direction = Direction.Right,
            },
            Bullet{
                .coordinates = Vector2D{ .x = 15, .y = 10 },
                .active = true,
                .direction = Direction.Right,
            },
            Bullet{
                .coordinates = Vector2D{ .x = 30, .y = 25 },
                .active = true,
                .direction = Direction.Right,
            },
            Bullet{
                .coordinates = Vector2D{ .x = 10, .y = 40 },
                .active = true,
                .direction = Direction.Right,
            },
        },
    }, Player{
        .coordinates = Vector2D{ .x = 1, .y = 2 },
        .hp = 100,
        .alive = true,
        .direction = Direction.Up,
        .bullets = .{
            Bullet{
                .coordinates = Vector2D{ .x = 10, .y = 20 },
                .active = true,
                .direction = Direction.Right,
            },
            Bullet{
                .coordinates = Vector2D{ .x = 20, .y = 20 },
                .active = true,
                .direction = Direction.Right,
            },
            Bullet{
                .coordinates = Vector2D{ .x = 15, .y = 10 },
                .active = true,
                .direction = Direction.Right,
            },
            Bullet{
                .coordinates = Vector2D{ .x = 30, .y = 25 },
                .active = true,
                .direction = Direction.Right,
            },
            Bullet{
                .coordinates = Vector2D{ .x = 10, .y = 40 },
                .active = true,
                .direction = Direction.Right,
            },
        },
    }, Player{
        .coordinates = Vector2D{ .x = 1, .y = 2 },
        .hp = 100,
        .alive = true,
        .direction = Direction.Up,
        .bullets = .{
            Bullet{
                .coordinates = Vector2D{ .x = 10, .y = 20 },
                .active = true,
                .direction = Direction.Right,
            },
            Bullet{
                .coordinates = Vector2D{ .x = 20, .y = 20 },
                .active = true,
                .direction = Direction.Right,
            },
            Bullet{
                .coordinates = Vector2D{ .x = 25, .y = 10 },
                .active = true,
                .direction = Direction.Right,
            },
            Bullet{
                .coordinates = Vector2D{ .x = 32, .y = 25 },
                .active = true,
                .direction = Direction.Right,
            },
            Bullet{
                .coordinates = Vector2D{ .x = 14, .y = 40 },
                .active = true,
                .direction = Direction.Right,
            },
        },
    }, Player{
        .coordinates = Vector2D{ .x = 1, .y = 2 },
        .hp = 100,
        .alive = true,
        .direction = Direction.Up,
        .bullets = .{
            Bullet{
                .coordinates = Vector2D{ .x = 10, .y = 120 },
                .active = true,
                .direction = Direction.Right,
            },
            Bullet{
                .coordinates = Vector2D{ .x = 22, .y = 21 },
                .active = true,
                .direction = Direction.Right,
            },
            Bullet{
                .coordinates = Vector2D{ .x = 19, .y = 10 },
                .active = true,
                .direction = Direction.Right,
            },
            Bullet{
                .coordinates = Vector2D{ .x = 30, .y = 25 },
                .active = true,
                .direction = Direction.Right,
            },
            Bullet{
                .coordinates = Vector2D{ .x = 10, .y = 40 },
                .active = true,
                .direction = Direction.Right,
            },
        },
    }, Player{
        .coordinates = Vector2D{ .x = 1, .y = 20 },
        .hp = 100,
        .alive = true,
        .direction = Direction.Up,
        .bullets = .{
            Bullet{
                .coordinates = Vector2D{ .x = 10, .y = 20 },
                .active = true,
                .direction = Direction.Right,
            },
            Bullet{
                .coordinates = Vector2D{ .x = 20, .y = 20 },
                .active = true,
                .direction = Direction.Right,
            },
            Bullet{
                .coordinates = Vector2D{ .x = 15, .y = 10 },
                .active = true,
                .direction = Direction.Right,
            },
            Bullet{
                .coordinates = Vector2D{ .x = 30, .y = 25 },
                .active = true,
                .direction = Direction.Right,
            },
            Bullet{
                .coordinates = Vector2D{ .x = 10, .y = 40 },
                .active = true,
                .direction = Direction.Right,
            },
        },
    } };

    const game_state = GameState{
        .player_index = 0,
        .active_players = 1,
        .power_up = power_up,
        .players = players,
    };

    // Encode the game state into a buffer
    const buffer = try encode(game_state, allocator);

    // Decode the buffer back into a GameState
    const decoded_game_state = try decode(buffer);

    // Assert that the original game state and the decoded game state are equal
    try testing.expect(game_state.player_index == decoded_game_state.player_index);
    try testing.expect(game_state.active_players == decoded_game_state.active_players);
    try testing.expect(game_state.power_up.coordinates.x == decoded_game_state.power_up.coordinates.x);
    try testing.expect(game_state.power_up.coordinates.y == decoded_game_state.power_up.coordinates.y);
    try testing.expect(game_state.power_up.kind == decoded_game_state.power_up.kind);

    // Check players
    for (0.., game_state.players) |index, player| {
        const decoded_player = decoded_game_state.players[index];
        try testing.expect(player.coordinates.x == decoded_player.coordinates.x);
        try testing.expect(player.coordinates.y == decoded_player.coordinates.y);
        try testing.expect(player.hp == decoded_player.hp);
        try testing.expect(player.alive == decoded_player.alive);
        try testing.expect(player.direction == decoded_player.direction);

        // Check bullets
        for (0.., player.bullets) |bullet_index, bullet| {
            const decoded_bullet = decoded_player.bullets[bullet_index];
            try testing.expect(bullet.coordinates.x == decoded_bullet.coordinates.x);
            try testing.expect(bullet.coordinates.y == decoded_bullet.coordinates.y);
            try testing.expect(bullet.active == decoded_bullet.active);
            try testing.expect(bullet.direction == decoded_bullet.direction);
        }
    }
}

test "empty game state serializes and deserializes correctly" {
    const allocator = std.heap.page_allocator;

    const game_state = GameState{
        .player_index = 0,
        .active_players = 0,
        .power_up = PowerUp{ .coordinates = Vector2D{ .x = 0, .y = 0 }, .kind = PowerUpKind.None },
        .players = undefined,
    };

    // Encode and decode the empty game state
    const buffer = try encode(game_state, allocator);
    const decoded_game_state = try decode(buffer);

    // Assert that the decoded game state matches the original empty state
    try testing.expect(game_state.player_index == decoded_game_state.player_index);
    try testing.expect(game_state.active_players == decoded_game_state.active_players);
    try testing.expect(game_state.power_up.kind == decoded_game_state.power_up.kind);
}
