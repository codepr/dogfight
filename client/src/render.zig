const std = @import("std");
const gs = @import("gamestate.zig");
const rl = @import("raylib");

// const sprite_path_size = 192;

pub const SpriteKind = enum {
    SpaceShip,
    Bullet,
    PowerUp,
};

pub const Sprite = struct {
    path: [*:0]const u8,
    scaling: f32,
    kind: SpriteKind,
    texture: rl.Texture2D,
};

pub fn init(width: comptime_int, height: comptime_int, fps: comptime_int) void {
    rl.initWindow(width, height, "Dogfight Arena");
    rl.setTargetFPS(fps);
}

pub fn drawGameState(state: *const gs.GameState) void {
    rl.beginDrawing();
    defer rl.endDrawing();
    rl.clearBackground(rl.Color.ray_white);

    // Generic sprite placeholder
    // TODO add assets and load real sprites
    const sprite = loadSprite("assets/sprites/spaceships/default.png", SpriteKind.SpaceShip, 0.12);
    var iterator = state.players.valueIterator();
    while (iterator.next()) |player| {
        drawPlayer(player, &sprite);
    }
    // Draw game state: players, bullets, power-ups, etc.
}

pub fn text(txt: [*:0]const u8, x: i32, y: i32, font_size: i32) void {
    rl.drawText(txt, x, y, font_size, rl.Color.light_gray);
}

pub fn windowIsOpen() bool {
    return !rl.windowShouldClose();
}

pub fn shutdown() void {
    rl.closeWindow();
}

fn loadSprite(path: [*:0]const u8, kind: SpriteKind, scaling: f32) Sprite {
    return Sprite{
        .path = path,
        .kind = kind,
        .scaling = scaling,
        .texture = rl.loadTexture(path),
    };
}

fn drawPlayer(player: *const gs.Player, sprite: *const Sprite) void {
    if (!player.alive) return;

    const rotation: f32 = switch (player.direction) {
        gs.Direction.Up => 0.0,
        gs.Direction.Right => 90.0,
        gs.Direction.Down => 180.0,
        gs.Direction.Left => 270.0,
    };

    const x: f32 = @floatFromInt(player.position.x);
    const y: f32 = @floatFromInt(player.position.x);
    const texture_width: f32 = @floatFromInt(sprite.texture.width);
    const texture_height: f32 = @floatFromInt(sprite.texture.height);

    const src_rec = rl.Rectangle{ .x = 0.0, .y = 0.0, .width = texture_width, .height = texture_height };

    // Define destination rectangle (where and how to draw the texture)
    const dst_rec = rl.Rectangle{ .x = x, .y = y, .width = texture_width * sprite.scaling, .height = texture_height * sprite.scaling }; // Position and

    // Define origin for rotation (center of the texture)
    const origin = rl.Vector2{ .x = (texture_width * sprite.scaling) / 2.0, .y = (texture_height * sprite.scaling) / 2.0 };

    rl.drawTexturePro(sprite.texture, src_rec, dst_rec, origin, rotation, rl.Color.white);

    // TODO draw bullets and powerups
}
