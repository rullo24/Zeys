const std = @import("std");
const zeys = @import("zeys");

/// Continuously checks and prints whether the 'A' key is pressed. 
/// The state is updated every 50 milliseconds in an infinite loop.
pub fn main() !void {
    while (true) {
        // Print the current state of the 'A' key (whether it is pressed or not)
        std.debug.print("\rA is Pressed: {any}", .{ zeys.isPressed(zeys.VK.VK_A) });

        // Wait 50ms before again checking if the 'A' key is pressed
        std.Thread.sleep(std.time.ns_per_ms * 50);
    }
}