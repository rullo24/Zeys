const std = @import("std");
const zeys = @import("zeys");
const print = std.debug.print;

fn tester_func(args: *anyopaque) void {
    _ = args;

    const p_file = std.fs.openFileAbsolute("F:\\Coding\\01.Projects\\06.Zig\\01-Zeys\\example\\zig-out\\bin\\hey.txt", .{}) catch null;
    if (p_file) |file| {
        file.close();
    }
}

// pressing a singular key --> displaying in console stdin
pub fn main() !void {
    // var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    // const alloc = gpa.allocator();
    // defer _ = gpa.deinit();

    _ = try zeys.initMsgCallback();
    defer zeys.deinitMsgCallback();

    var ex_string: u8 = 'c';
    const my_args: *anyopaque = @ptrCast(&ex_string);

    try zeys.bindHotkey(.{ zeys.VK.VK_P, zeys.VK.VK_CONTROL, zeys.VK.VK_SHIFT }, &tester_func, my_args, false);



    zeys.zeysInfWait();

    return;
}