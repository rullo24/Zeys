const std = @import("std");
const zeys = @import("zeys");
const print = std.debug.print;

// pressing a singular key --> displaying in console stdin
pub fn main() !void {
    // std.time.sleep(std.time.ns_per_s * 2);
    // try zeys.pressAndReleaseKey(zeys.VK_ENUM.VK_A);

    print("{s}\n", .{ try zeys.getKeyboardLocaleIdentifier() } );

    zeys.zeysInfWait();

    return;
}