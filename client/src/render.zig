const std = @import("std");
const gs = @import("gamestate.zig");
const rl = @import("raylib");
const repo = @import("sprite_repo.zig");

const assets_path = "./assets";
const spaceship_asset_path = assets_path ++ "/spaceships/default.png";
const power_up_asset_path = assets_path ++ "/powerups/default.png";
const bullet_asset_path = assets_path ++ "/bullets/default.png";

pub const Renderer = struct {
    repo: repo.SpriteRepo,

    pub fn init(width: comptime_int, height: comptime_int, fps: comptime_int, allocator: std.mem.Allocator) !Renderer {
        rl.initWindow(width, height, "Dogfight Arena");
        rl.setTargetFPS(fps);

        var repository = repo.SpriteRepo.init(allocator);

        // Load sprites
        try repository.loadSprite("default_spaceship", spaceship_asset_path, repo.SpriteKind.spaceship);
        try repository.loadSprite("default_power_up", power_up_asset_path, repo.SpriteKind.power_up);
        try repository.loadSprite("default_bullet", bullet_asset_path, repo.SpriteKind.bullet);

        return Renderer{ .repo = repository };
    }

    pub fn deinit(self: *Renderer) void {
        self.repo.deinit();
        rl.closeWindow();
    }

    pub fn drawGameState(self: *Renderer, state: *const gs.GameState) void {
        rl.beginDrawing();
        defer rl.endDrawing();
        rl.clearBackground(rl.Color.ray_white);

        // Generic sprite placeholder
        const sprite = self.repo.getSprite("default_spaceship").?;
        var iterator = state.players.valueIterator();
        while (iterator.next()) |player| {
            self.drawPlayer(player, &sprite);
        }

        const power_up_sprite = self.repo.getSprite("default_power_up").?;
        for (state.power_ups) |power_up| {
            drawEntity(power_up.position.x, power_up.position.y, 0.0, &power_up_sprite);
        }
    }

    fn drawPlayer(self: *Renderer, player: *const gs.Player, sprite: *const repo.Sprite) void {
        if (!player.alive) return;

        const rotation: f32 = switch (player.direction) {
            gs.Direction.idle => 0.0,
            gs.Direction.up => 0.0,
            gs.Direction.right => 90.0,
            gs.Direction.down => 180.0,
            gs.Direction.left => 270.0,
        };

        drawEntity(player.position.x, player.position.y, rotation, sprite);

        const bullet_sprite = self.repo.getSprite("default_bullet").?;
        for (player.bullets) |bullet| {
            drawBullet(&bullet, &bullet_sprite);
        }
    }

    fn drawBullet(bullet: *const gs.Bullet, sprite: *const repo.Sprite) void {
        if (!bullet.active) return;

        const rotation: f32 = switch (bullet.direction) {
            gs.Direction.idle => 0.0,
            gs.Direction.up => 270.0,
            gs.Direction.right => 0.0,
            gs.Direction.down => 90.0,
            gs.Direction.left => 180.0,
        };

        drawEntity(bullet.position.x, bullet.position.y, rotation, sprite);
    }
};

pub fn text(txt: [*:0]const u8, x: i32, y: i32, font_size: i32) void {
    rl.drawText(txt, x, y, font_size, rl.Color.light_gray);
}

pub fn windowIsOpen() bool {
    return !rl.windowShouldClose();
}

fn drawEntity(xpos: i32, ypos: i32, rotation: f32, sprite: *const repo.Sprite) void {
    const x: f32 = @floatFromInt(xpos);
    const y: f32 = @floatFromInt(ypos);
    const texture_width: f32 = @floatFromInt(sprite.texture.width);
    const texture_height: f32 = @floatFromInt(sprite.texture.height);

    const src_rec = rl.Rectangle{ .x = 0.0, .y = 0.0, .width = texture_width, .height = texture_height };

    // Define destination rectangle (where and how to draw the texture)
    const dst_rec = rl.Rectangle{ .x = x, .y = y, .width = texture_width * sprite.scaling, .height = texture_height * sprite.scaling }; // Position and

    // Define origin for rotation (center of the texture)
    const origin = rl.Vector2{ .x = (texture_width * sprite.scaling) / 2.0, .y = (texture_height * sprite.scaling) / 2.0 };

    rl.drawTexturePro(sprite.texture, src_rec, dst_rec, origin, rotation, rl.Color.white);
}
