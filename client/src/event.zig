const std = @import("std");
const gs = @import("gamestate.zig");

pub const PlayerId = [36]u8;

const move_u8: u8 = 2;
const shoot_u8: u8 = 3;

pub const Event = union(enum) {
    move: MoveEvent,
    shoot: PlayerId,

    pub const MoveEvent = struct {
        player_id: PlayerId,
        direction: gs.Direction,
    };
};

pub fn encode(event: Event, allocator: std.mem.Allocator) ![]u8 {
    return switch (event) {
        .move => |move_event| {
            const buffer = try allocator.alloc(u8, @sizeOf(u8) + @sizeOf(Event.MoveEvent));
            errdefer allocator.free(buffer); // Ensure buffer is freed on error

            var buffered_stream = std.io.fixedBufferStream(buffer);
            var writer = buffered_stream.writer();
            try writer.writeInt(u8, move_u8, .big);
            try writer.writeInt(u8, @intFromEnum(move_event.direction), .big);
            try writer.writeAll(&move_event.player_id);

            return buffer;
        },
        .shoot => |player_id| {
            const buffer = try allocator.alloc(u8, @sizeOf(u8) + @sizeOf(PlayerId));
            errdefer allocator.free(buffer); // Ensure buffer is freed on error

            var buffered_stream = std.io.fixedBufferStream(buffer);
            var writer = buffered_stream.writer();
            try writer.writeInt(u8, shoot_u8, .big);
            try writer.writeAll(&player_id);

            return buffer;
        },
    };
}
