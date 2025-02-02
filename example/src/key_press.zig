const std = @import("std");
const zeys = @import("zeys");
const print = std.debug.print;

const test_struct = packed struct {
    inte: i32 = 400,
    third: u64 = 10000000,
    second: u16 = 50,
};

fn tester_func(args: *anyopaque) void {
    const p_c: *test_struct = @ptrCast(@alignCast(args));

    std.debug.print("In func {d} | {d} | {d}\n", .{p_c.inte, p_c.second, p_c.third});
}

// pressing a singular key --> displaying in console stdin
pub fn main() !void {
    var tester: test_struct = .{};

    // const my_args: *anyopaque = @ptrCast(&test_struct);
    try zeys.bindHotkey(.{ zeys.VK.VK_A, zeys.VK.VK_CONTROL, zeys.VK.VK_SHIFT }, &tester_func, @ptrCast(&tester), false);

    try zeys.waitUntilKeysPressed(.{zeys.VK.VK_0, zeys.VK.UNDEFINED, zeys.VK.UNDEFINED});

    return;
}