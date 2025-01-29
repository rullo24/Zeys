const std = @import("std");
const zeys = @import("zeys");

// pressing a singular key --> displaying in console stdin
pub fn main() !void {
    try zeys.pressKey(zeys.VK_ENUM.VK_A);

    return;
}