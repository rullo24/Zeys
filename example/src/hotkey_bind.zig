const std = @import("std");
const zeys = @import("zeys");

const test_struct_1 = packed struct {
    inte: i32 = 400,
    third: u64 = 10000000,
    second: u16 = 50,
};

const test_struct_2 = packed struct {
    first: u8,
    second: u39,
    third: u2
};

const test_struct_3 = struct {
    first: [4]u8,
    second: [3]u8,
    third: [7]u8,
};

fn tester_func_1(args: *anyopaque) void {
    const p_struct_1: *test_struct_1 = @ptrCast(@alignCast(args)); // @alignCast required before @ptrCast ALWAYS
    std.debug.print("In func {d} | {d} | {d}\n", .{p_struct_1.inte, p_struct_1.second, p_struct_1.third});
}

fn tester_func_2(args: *anyopaque) void {
    const p_struct_2: *test_struct_2 = @ptrCast(@alignCast(args)); // @alignCast required before @ptrCast ALWAYS
    std.testing.expect(p_struct_2.second == 300000) catch std.debug.print("FAILED\n", .{});
    std.testing.expect(p_struct_2.second != p_struct_2.third) catch std.debug.print("FAILED\n", .{});
    std.testing.expect(p_struct_2.first == 'h') catch std.debug.print("FAILED\n", .{});
    std.debug.print("SUCCESSFUL RUN\n", .{});
}

fn tester_func_3(args: *anyopaque) void {
    const p_struct_3: *test_struct_3 = @ptrCast(@alignCast(args)); // @alignCast required before @ptrCast ALWAYS
    std.debug.print("{s} {s} {s}\n", .{ p_struct_3.first, p_struct_3.second, p_struct_3.third });
}


// pressing a singular key --> displaying in console stdin
pub fn main() !void {
    // press A + CTRL + SHIFT to activate callback --> '0' key skips to next example
    std.debug.print("Press A + CTRL + SHIFT to run tester_func_1\n", .{});
    std.debug.print("Press 0 to move to the next example\n", .{});
    var tester_1: test_struct_1 = .{};
    try zeys.bindHotkey(.{ zeys.VK.VK_A, zeys.VK.VK_CONTROL, zeys.VK.VK_SHIFT, zeys.VK.UNDEFINED, zeys.VK.UNDEFINED }, &tester_func_1, @ptrCast(&tester_1), false);
    try zeys.waitUntilKeysPressed(.{zeys.VK.VK_0, zeys.VK.UNDEFINED, zeys.VK.UNDEFINED, zeys.VK.UNDEFINED, zeys.VK.UNDEFINED });

    // press B key to activate callback --> '1' skips to next example
    std.debug.print("Press B to run tester_func_1\n", .{});
    std.debug.print("Press 1 to move to the next example\n", .{});
    var tester_2: test_struct_2 = .{ .first = 'h', .second = 300000, .third = 0x2 };
    // bool at end of bindHotkey() call is for repeating the callback after holding the key
    try zeys.bindHotkey(.{ zeys.VK.VK_B, zeys.VK.UNDEFINED, zeys.VK.UNDEFINED, zeys.VK.UNDEFINED, zeys.VK.UNDEFINED }, &tester_func_2, @ptrCast(&tester_2), true); 
    try zeys.waitUntilKeysPressed(.{zeys.VK.VK_1, zeys.VK.UNDEFINED, zeys.VK.UNDEFINED, zeys.VK.UNDEFINED, zeys.VK.UNDEFINED });

    std.debug.print("Press C to run tester_func_1\n", .{});
    std.debug.print("Press 2 to end the examples\n", .{});
    // var tester_3: test_struct_3 = .{.first = "hey", .second = "how", .third = "are you"};
    var tester_3: test_struct_3 = undefined;
    @memcpy(&tester_3.first, "hey,");
    @memcpy(&tester_3.second, "how");
    @memcpy(&tester_3.third, "are you");
    try zeys.bindHotkey(.{ zeys.VK.VK_C, zeys.VK.UNDEFINED, zeys.VK.UNDEFINED, zeys.VK.UNDEFINED, zeys.VK.UNDEFINED }, &tester_func_3, @ptrCast(&tester_3), true); 
    try zeys.waitUntilKeysPressed(.{zeys.VK.VK_2, zeys.VK.UNDEFINED, zeys.VK.UNDEFINED, zeys.VK.UNDEFINED, zeys.VK.UNDEFINED });
}