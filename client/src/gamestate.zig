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
//!     A struct representing a power-up, including its position and type.
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
    position: Vector2D,
    direction: Direction,
    active: bool,

    pub fn print(self: Bullet, writer: anytype) !void {
        try writer.print("    position: ", .{});
        try self.position.print(writer);
        try writer.print(" Direction: ", .{});
        try self.direction.print(writer);
        try writer.print(" Active: {s}\n", .{if (self.active) "true" else "false"});
    }
};

const Player = struct {
    position: Vector2D,
    hp: i32,
    direction: Direction,
    alive: bool,
    bullets: [max_bullets]Bullet,

    pub fn print(self: Player, writer: anytype) !void {
        try writer.print("   position: ", .{});
        try self.position.print(writer);
        try writer.print("   HP: {d}\n", .{self.hp});
        try writer.print("   Direction: ", .{});
        try self.direction.print(writer);
        try writer.print(" Alive: {s}\n", .{if (self.alive) "true" else "false"});

        try writer.print("   Bullets:\n", .{});
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

const GameStatus = enum {
    InProgress,
    Closed,

    pub fn print(self: GameStatus, writer: anytype) !void {
        const status_names = [_][]const u8{ "In Progress", "Closed" };
        try writer.print("{s}", .{status_names[@intFromEnum(self)]});
    }
};

const PowerUp = struct {
    position: Vector2D,
    kind: PowerUpKind,

    pub fn print(self: PowerUp, writer: anytype) !void {
        try writer.print("position: ", .{});
        try self.position.print(writer);
        try writer.print(" Kind: ", .{});
        try self.kind.print(writer);
        try writer.print("\n", .{});
    }
};

const GameState = struct {
    players: std.StringHashMap(Player),
    status: GameStatus,
    power_ups: []PowerUp,

    pub fn print(self: GameState, writer: anytype) !void {
        try writer.print("GameState:\n", .{});
        try writer.print(" Power ups:\n", .{});
        for (self.power_ups) |power_up| {
            try power_up.print(writer);
        }

        try writer.print(" Players:\n", .{});
        var iterator = self.players.iterator();
        var player_index: usize = 0;
        while (iterator.next()) |entry| {
            try writer.print("  Player {d} - {s}:\n", .{ player_index, entry.key_ptr.* });
            try entry.value_ptr.print(writer);
            player_index += 1;
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
    try writer.writeInt(u8, @intFromEnum(game_state.status), .big);
    try encode_power_ups(writer, game_state.power_ups);

    var iterator = game_state.players.iterator();

    while (iterator.next()) |entry| {
        try writer.writeInt(i32, entry.value_ptr.position.x, .big);
        try writer.writeInt(i32, entry.value_ptr.position.y, .big);
        try writer.writeInt(u8, entry.value_ptr.hp, .big);
        try writer.writeInt(u8, @intFromBool(entry.value_ptr.alive), .big);
        try writer.writeInt(u8, @intFromEnum(entry.value_ptr.direction), .big);
        try writer.writeAll(entry.key_ptr);

        for (entry.value_ptr.bullets) |bullet| {
            try writer.writeInt(i32, bullet.position.x, .big);
            try writer.writeInt(i32, bullet.position.y, .big);
            try writer.writeInt(u8, @intFromBool(bullet.active), .big);
            try writer.writeInt(u8, @intFromEnum(bullet.direction), .big);
        }
    }
    return buffer;
}

fn encode_power_ups(writer: std.io.Writer, power_ups: []PowerUp) !void {
    const size = power_ups.len * ((@sizeOf(i32) * 2) + @sizeOf(u8));

    try writer.writeInt(i16, size, .big);

    for (power_ups) |power_up| {
        try writer.writeInt(i32, power_up.position.x, .big);
        try writer.writeInt(i32, power_up.position.y, .big);
        try writer.writeInt(u8, @intFromEnum(power_up.kind), .big);
    }
}

pub fn decode(buffer: []const u8) !GameState {
    var buffered_stream = std.io.fixedBufferStream(buffer);
    var reader = buffered_stream.reader();

    const total_length = try reader.readInt(i32, .big);
    const game_status = try reader.readByte();

    const power_ups = try decode_power_ups(reader);

    const player_size = @sizeOf(i32) * 2 + @sizeOf(u8) * 3 + 36 + ((@sizeOf(i32) * 2) + (@sizeOf(u8) * 2));

    const usize_total_length: usize = @intCast(total_length);

    const players_count = (usize_total_length - (power_ups.len * ((@sizeOf(i32) * 2) + @sizeOf(u8))) - @sizeOf(u8) - @sizeOf(i32)) / player_size;

    const allocator = std.heap.page_allocator;

    var players = std.StringHashMap(Player).init(allocator);
    for (0..players_count) |_| {
        var player = Player{
            .position = Vector2D{
                .x = try reader.readInt(i32, .big),
                .y = try reader.readInt(i32, .big),
            },
            .hp = try reader.readInt(u8, .big),
            .alive = try reader.readInt(u8, .big) != 0, // Deserialize bool as u8
            .direction = @enumFromInt(try reader.readInt(u8, .big)),
            .bullets = undefined,
        };

        var binary_player_id: [36]u8 = undefined;
        _ = try reader.readAll(&binary_player_id);

        const player_id = try std.fmt.allocPrint(allocator, "{s}", .{binary_player_id[0..]});

        var bullets: [max_bullets]Bullet = undefined;
        for (&bullets) |*bullet| {
            bullet.position = Vector2D{
                .x = try reader.readInt(i32, .big),
                .y = try reader.readInt(i32, .big),
            };
            bullet.active = try reader.readInt(u8, .big) != 0; // Deserialize bool as u8
            bullet.direction = @enumFromInt(try reader.readInt(u8, .big));
        }
        player.bullets = bullets; // Assign bullets array

        try players.put(player_id, player);
    }

    return GameState{ .players = players, .power_ups = power_ups, .status = @enumFromInt(game_status) };
}

fn decode_power_ups(reader: anytype) ![]PowerUp {
    const allocator = std.heap.page_allocator;
    const raw_size = try reader.readInt(i16, .big);
    const size = @divExact(raw_size, ((@sizeOf(i32) * 2) + @sizeOf(u8)));

    if (size < 0) {
        return error.InvalidSize; // Return an error for negative size
    }

    const usize_size: usize = @intCast(size);

    const power_ups = try allocator.alloc(PowerUp, usize_size);
    for (power_ups) |*power_up| {
        power_up.position = Vector2D{ .x = try reader.readInt(i32, .big), .y = try reader.readInt(i32, .big) };
        power_up.kind = @enumFromInt(try reader.readByte());
    }

    return power_ups;
}

test "serialization and deserialization work correctly" {
    const allocator = std.heap.page_allocator;

    const power_up = PowerUp{
        .position = Vector2D{ .x = 10, .y = 20 },
        .kind = PowerUpKind.HpPlusOne,
    };

    const status = GameStatus.InProgress;

    const players: [max_players]Player = .{ Player{
        .position = Vector2D{ .x = 1, .y = 2 },
        .hp = 100,
        .alive = true,
        .direction = Direction.Up,
        .bullets = .{
            Bullet{
                .position = Vector2D{ .x = 10, .y = 20 },
                .active = true,
                .direction = Direction.Right,
            },
            Bullet{
                .position = Vector2D{ .x = 20, .y = 20 },
                .active = true,
                .direction = Direction.Right,
            },
            Bullet{
                .position = Vector2D{ .x = 15, .y = 10 },
                .active = true,
                .direction = Direction.Right,
            },
            Bullet{
                .position = Vector2D{ .x = 30, .y = 25 },
                .active = true,
                .direction = Direction.Right,
            },
            Bullet{
                .position = Vector2D{ .x = 10, .y = 40 },
                .active = true,
                .direction = Direction.Right,
            },
        },
    }, Player{
        .position = Vector2D{ .x = 1, .y = 2 },
        .hp = 100,
        .alive = true,
        .direction = Direction.Up,
        .bullets = .{
            Bullet{
                .position = Vector2D{ .x = 10, .y = 20 },
                .active = true,
                .direction = Direction.Right,
            },
            Bullet{
                .position = Vector2D{ .x = 20, .y = 20 },
                .active = true,
                .direction = Direction.Right,
            },
            Bullet{
                .position = Vector2D{ .x = 15, .y = 10 },
                .active = true,
                .direction = Direction.Right,
            },
            Bullet{
                .position = Vector2D{ .x = 30, .y = 25 },
                .active = true,
                .direction = Direction.Right,
            },
            Bullet{
                .position = Vector2D{ .x = 10, .y = 40 },
                .active = true,
                .direction = Direction.Right,
            },
        },
    }, Player{
        .position = Vector2D{ .x = 1, .y = 2 },
        .hp = 100,
        .alive = true,
        .direction = Direction.Up,
        .bullets = .{
            Bullet{
                .position = Vector2D{ .x = 10, .y = 20 },
                .active = true,
                .direction = Direction.Right,
            },
            Bullet{
                .position = Vector2D{ .x = 20, .y = 20 },
                .active = true,
                .direction = Direction.Right,
            },
            Bullet{
                .position = Vector2D{ .x = 25, .y = 10 },
                .active = true,
                .direction = Direction.Right,
            },
            Bullet{
                .position = Vector2D{ .x = 32, .y = 25 },
                .active = true,
                .direction = Direction.Right,
            },
            Bullet{
                .position = Vector2D{ .x = 14, .y = 40 },
                .active = true,
                .direction = Direction.Right,
            },
        },
    }, Player{
        .position = Vector2D{ .x = 1, .y = 2 },
        .hp = 100,
        .alive = true,
        .direction = Direction.Up,
        .bullets = .{
            Bullet{
                .position = Vector2D{ .x = 10, .y = 120 },
                .active = true,
                .direction = Direction.Right,
            },
            Bullet{
                .position = Vector2D{ .x = 22, .y = 21 },
                .active = true,
                .direction = Direction.Right,
            },
            Bullet{
                .position = Vector2D{ .x = 19, .y = 10 },
                .active = true,
                .direction = Direction.Right,
            },
            Bullet{
                .position = Vector2D{ .x = 30, .y = 25 },
                .active = true,
                .direction = Direction.Right,
            },
            Bullet{
                .position = Vector2D{ .x = 10, .y = 40 },
                .active = true,
                .direction = Direction.Right,
            },
        },
    }, Player{
        .position = Vector2D{ .x = 1, .y = 20 },
        .hp = 100,
        .alive = true,
        .direction = Direction.Up,
        .bullets = .{
            Bullet{
                .position = Vector2D{ .x = 10, .y = 20 },
                .active = true,
                .direction = Direction.Right,
            },
            Bullet{
                .position = Vector2D{ .x = 20, .y = 20 },
                .active = true,
                .direction = Direction.Right,
            },
            Bullet{
                .position = Vector2D{ .x = 15, .y = 10 },
                .active = true,
                .direction = Direction.Right,
            },
            Bullet{
                .position = Vector2D{ .x = 30, .y = 25 },
                .active = true,
                .direction = Direction.Right,
            },
            Bullet{
                .position = Vector2D{ .x = 10, .y = 40 },
                .active = true,
                .direction = Direction.Right,
            },
        },
    } };

    const game_state = GameState{ .power_ups = .{power_up}, .players = players, .status = status };

    // Encode the game state into a buffer
    const buffer = try encode(game_state, allocator);

    // Decode the buffer back into a GameState
    const decoded_game_state = try decode(buffer);

    // Assert that the original game state and the decoded game state are equal
    try testing.expect(game_state.power_ups[0].position.x == decoded_game_state.power_ups[0].position.x);
    try testing.expect(game_state.power_ups[0].position.y == decoded_game_state.power_ups[0].position.y);
    try testing.expect(game_state.power_ups[0].kind == decoded_game_state.power_ups[0].kind);

    var iterator = decoded_game_state.players.iterator();

    // Check players
    while (iterator.next()) |entry| {
        const player = try game_state.players[entry.key_ptr];
        const decoded_player = entry.value_ptr;
        try testing.expect(player.position.x == decoded_player.position.x);
        try testing.expect(player.position.y == decoded_player.position.y);
        try testing.expect(player.hp == decoded_player.hp);
        try testing.expect(player.alive == decoded_player.alive);
        try testing.expect(player.direction == decoded_player.direction);

        // Check bullets
        for (0.., player.bullets) |bullet_index, bullet| {
            const decoded_bullet = decoded_player.bullets[bullet_index];
            try testing.expect(bullet.position.x == decoded_bullet.position.x);
            try testing.expect(bullet.position.y == decoded_bullet.position.y);
            try testing.expect(bullet.active == decoded_bullet.active);
            try testing.expect(bullet.direction == decoded_bullet.direction);
        }
    }
}

test "empty game state serializes and deserializes correctly" {
    const allocator = std.heap.page_allocator;

    const game_state = GameState{
        .power_ups = .{PowerUp{ .position = Vector2D{ .x = 0, .y = 0 }, .kind = PowerUpKind.None }},
        .status = GameStatus.InProgress,
        .players = undefined,
    };

    // Encode and decode the empty game state
    const buffer = try encode(game_state, allocator);
    const decoded_game_state = try decode(buffer);

    // Assert that the decoded game state matches the original empty state
    try testing.expect(game_state.status == decoded_game_state.status);
    try testing.expect(game_state.power_ups[0].kind == decoded_game_state.power_ups[0].kind);
}
