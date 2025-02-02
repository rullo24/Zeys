const std = @import("std");
const zeys = @import("zeys");

/// isToggled() checks if a togglable key is currently in the active toggle mode i.e. CAPS_LOCK, SCREEN_LOCK or NUM_LOCK
pub fn main() !void {
    const example_version: u8 = 1;

    // EXAMPLE 1
    if (example_version == 1) {
        while (true) {
            std.debug.print("Caps Lock Toggle State: {any}\n", .{ zeys.isToggled(zeys.VK.VK_CAPITAL) });
        }   
    }

    // EXAMPLE 2
    if (example_version == 2) {
        while (zeys.isToggled(zeys.VK.VK_NUMLOCK) != true) {
            std.time.sleep(std.time.ns_per_ms * 20);
        }
    }
}