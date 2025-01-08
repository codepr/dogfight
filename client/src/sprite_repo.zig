const std = @import("std");
const rl = @import("raylib");

const default_scaling = 0.12;

pub const SpriteKind = enum {
    spaceship,
    bullet,
    power_up,
};

pub const Sprite = struct {
    path: [*:0]const u8,
    scaling: f32,
    kind: SpriteKind,
    texture: rl.Texture2D,
};

pub const SpriteRepo = struct {
    allocator: std.mem.Allocator,
    sprites: std.StringHashMap(Sprite),

    pub fn init(allocator: std.mem.Allocator) SpriteRepo {
        return SpriteRepo{
            .allocator = allocator,
            .sprites = std.StringHashMap(Sprite).init(allocator),
        };
    }

    pub fn loadSprite(self: *SpriteRepo, name: []const u8, path: [*:0]const u8, kind: SpriteKind) !void {
        const sprite = Sprite{
            .path = path,
            .kind = kind,
            .scaling = default_scaling,
            .texture = rl.loadTexture(path),
        };
        try self.sprites.put(name, sprite);
    }

    pub fn getSprite(self: *SpriteRepo, name: []const u8) ?Sprite {
        return self.sprites.get(name);
    }

    pub fn deinit(self: *SpriteRepo) void {
        // Free all loaded sprites
        var it = self.sprites.iterator();
        while (it.next()) |entry| {
            rl.unloadTexture(entry.value_ptr.texture);
        }
        self.sprites.deinit();
    }
};
