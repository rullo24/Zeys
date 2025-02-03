const std = @import("std");
const zeys = @import("zeys");

/// Demonstrates binding hotkeys to functions using the zeys library.
/// This program binds different key combinations to execute functions that interact with custom structs.

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

/// Function to handle hotkey events for test_struct_1
// NOTE: parse in arguments as a "*void" equivalent struct --> even if there are no arguments
fn tester_func_1(args: *anyopaque) void {
    _ = args;
    std.debug.print("You're working in tester_func_1() :)\n", .{});
}

/// Function to handle hotkey events for test_struct_2
// NOTE: parse in arguments as a "*void" equivalent struct --> pointing to the struct where the arguments are held
fn tester_func_2(args: *anyopaque) void {
    const p_struct_2: *test_struct_2 = @ptrCast(@alignCast(args)); // @alignCast required before @ptrCast ALWAYS
    std.testing.expect(p_struct_2.second == 300000) catch std.debug.print("FAILED\n", .{});
    std.testing.expect(p_struct_2.second != p_struct_2.third) catch std.debug.print("FAILED\n", .{});
    std.testing.expect(p_struct_2.first == 'h') catch std.debug.print("FAILED\n", .{});
    std.debug.print("SUCCESSFUL RUN\n", .{});
}

/// Function to handle hotkey events for test_struct_3
// NOTE: parse in arguments as a "*void" equivalent struct --> pointing to the struct where the arguments are held
fn tester_func_3(args: *anyopaque) void {
    const p_struct_3: *test_struct_3 = @ptrCast(@alignCast(args)); // @alignCast required before @ptrCast ALWAYS
    std.debug.print("{s} {s} {s}\n", .{ p_struct_3.first, p_struct_3.second, p_struct_3.third });
}


/// Main function to set up hotkey bindings and execute callbacks
pub fn main() !void {
    // EXAMPLE 1: Binding Z + CTRL + SHIFT to tester_func_1
    std.debug.print("Press Z + CTRL + SHIFT to run tester_func_1\n", .{});
    std.debug.print("Press 0 to move to the next example\n", .{});
    // var tester_1: test_struct_1 = .{};
    try zeys.bindHotkey(&[_]zeys.VK{ zeys.VK.VK_Z, zeys.VK.VK_CONTROL, zeys.VK.VK_SHIFT, }, 
                            &tester_func_1, 
                            @constCast(&.{}), // need to parse an empty struct for no arguments --> casting struct to pointer
                            false);
    try zeys.waitUntilKeysPressed( &[_]zeys.VK{ zeys.VK.VK_0, });
    try zeys.unbindHotkey( &[_]zeys.VK{ zeys.VK.VK_Z, zeys.VK.VK_CONTROL, zeys.VK.VK_SHIFT, });

    // EXAMPLE 2: Binding B to tester_func_2
    std.debug.print("Press B to run tester_func_1\n", .{});
    std.debug.print("Press 1 to move to the next example\n", .{});
    std.debug.print("Try and press Z + CTRL + SHIFT again. It won't work because we have unbinded it\n", .{});
    
    try zeys.bindHotkey(&[_]zeys.VK{ zeys.VK.VK_B, zeys.VK.UNDEFINED, zeys.VK.UNDEFINED, zeys.VK.UNDEFINED, zeys.VK.UNDEFINED }, 
                            &tester_func_2, 
                            @constCast( &.{ .first = 'h', .second = 300000, .third = 0x2 } ), // casting struct to pointer
                            true); // bool at end of bindHotkey() call is for repeating the callback after holding the key
    try zeys.waitUntilKeysPressed(&[_]zeys.VK{ zeys.VK.VK_1 });

    // EXAMPLE 3: Binding C + LCTRL to tester_func_3
    std.debug.print("Press C + LCTRL (or RCTRL as modifiers are treated the same in Windows hotkeys) to run tester_func_1\n", .{});
    std.debug.print("Press 2 to end the examples\n", .{});
    std.debug.print("Try and press B. This hotkey will still function because we haven't unbinded it\n", .{});

    // IMPORTANT NOTE: In Windows hotkey modifiers, left and right modifier keys (e.g., LCTRL and RCTRL) are treated as equivalent.   
    var tester_3: test_struct_3 = undefined;
    @memcpy(&tester_3.first, "hey,");
    @memcpy(&tester_3.second, "how");
    @memcpy(&tester_3.third, "are you");
    try zeys.bindHotkey( &[_]zeys.VK{ zeys.VK.VK_C, zeys.VK.VK_LCONTROL, },
                            &tester_func_3, 
                            @ptrCast(&tester_3), // casting struct to pointer for easy serialisation
                            true); 
    try zeys.waitUntilKeysPressed( &[_]zeys.VK{zeys.VK.VK_2, zeys.VK.UNDEFINED, });
}