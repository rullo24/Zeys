const std = @import("std");
const zeys = @import("zeys");

/// Demonstrates the usage of `isToggled()` to check the state of toggle keys like CAPS_LOCK, NUM_LOCK, etc.
pub fn main() !void {
    // EXAMPLE 1: Print the current state of the Caps Lock key in an infinite loop
    while (true) {
        std.debug.print("Caps Lock Toggle State: {any}\n", .{ try zeys.isToggled(zeys.VK.VK_CAPITAL) });
        std.Thread.sleep(std.time.ns_per_ms * 50); // sleep for 50ms before next check
    }
}