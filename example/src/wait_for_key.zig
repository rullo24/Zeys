const std = @import("std");
const zeys = @import("zeys");
const print = std.debug.print;

/// Demonstrates waiting for specific key presses using zeys.
/// This program listens for individual and combination key presses before proceeding.
pub fn main() !void {
    // IMPORTANT NOTE: There are currently issues w/ binding to VK_LWIN or VK_RWIN --> use other keys for hotkey binding

    std.debug.print("Step 1: Waiting for A Key Press\n", .{});
    // Wait until the 'A' key is pressed
    try zeys.waitUntilKeysPressed( &[_]zeys.VK{ zeys.VK.VK_A } ); 
    std.debug.print("A Pressed\n", .{});

    std.debug.print("Step 2: Waiting for B + CTRL Key Press\n", .{});
    // Wait until 'B' and 'CTRL' keys are pressed simultaneously
    try zeys.waitUntilKeysPressed( &[_]zeys.VK{ zeys.VK.VK_B, zeys.VK.VK_CONTROL, zeys.VK.UNDEFINED, });
    std.debug.print("B + CTRL Pressed\n", .{});

    std.debug.print("Step 3: Waiting for C + SHIFT + CTRL Key Press\n", .{});
    // Wait until 'C', 'SHIFT', and 'Left Windows' keys are pressed together
    try zeys.waitUntilKeysPressed( &[_]zeys.VK{ zeys.VK.VK_C, zeys.VK.VK_SHIFT, zeys.VK.VK_CONTROL } );
    std.debug.print("C + SHIFT + CTRL Pressed\n", .{});

    std.debug.print("Step 4: Waiting for D + SHIFT + ALT + CTRL Key Press\n", .{});
    // Wait until 'C', 'SHIFT', and 'Left Windows' keys are pressed together
    try zeys.waitUntilKeysPressed( &[_]zeys.VK{ zeys.VK.VK_D, zeys.VK.VK_SHIFT, zeys.VK.VK_MENU, zeys.VK.VK_CONTROL, });
    std.debug.print("D + SHIFT + ALT + CTRL Pressed\n", .{});

    std.debug.print("Step 5: You cannot parse more than 5x keys to any key function\n", .{});
    std.time.sleep(std.time.ns_per_s);
    _ = zeys.waitUntilKeysPressed( &[_]zeys.VK{ zeys.VK.VK_D, zeys.VK.VK_SHIFT, zeys.VK.VK_MENU, zeys.VK.VK_CONTROL, zeys.VK.VK_LCONTROL, zeys.VK.UNDEFINED }) catch {
        std.debug.print("An error was found here (as expected)\n", .{});
    };

}