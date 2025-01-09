const rl = @import("raylib");

pub const Input = enum {
    move_up,
    move_left,
    move_right,
    move_down,
    shoot,
};

pub fn input() ?Input {
    if (rl.isKeyDown(rl.KeyboardKey.right)) return Input.move_right;
    if (rl.isKeyDown(rl.KeyboardKey.left)) return Input.move_left;
    if (rl.isKeyDown(rl.KeyboardKey.up)) return Input.move_up;
    if (rl.isKeyDown(rl.KeyboardKey.down)) return Input.move_down;
    if (rl.isKeyDown(rl.KeyboardKey.space)) return Input.shoot;
    return null; // No input
}
