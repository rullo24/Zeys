const std = @import("std");
const zeys = @import("zeys");
const print = std.debug.print;

pub fn main() !void {
    while (true) {
        std.debug.print("\rA is Pressed: {any}", .{ zeys.isPressed(zeys.VK.VK_A) });
        std.time.sleep(std.time.ns_per_ms * 50);
    }
}