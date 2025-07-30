const std = @import("std");
const zeys = @import("zeys");

pub fn main() !void {
    // defining buffer for current keys --> must be >= 255
    var vk_buf: [255]u8 = undefined;

    // returning slice of all pressed keys
    const keys_pressed: []zeys.VK = try zeys.getCurrPressedKeys(&vk_buf);
    for (keys_pressed) |key_vk| {
        zeys.
    }
}