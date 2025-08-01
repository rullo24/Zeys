const std = @import("std");
const zeys = @import("zeys");

pub fn main() !void {
    // defining buffer for current keys --> must be >= 255
    var vk_buf: [255]zeys.VK = undefined;
    var vk_compare_slice: []zeys.VK = &vk_buf;
    vk_compare_slice.len = 0;

    // printing currently pressed keys --> inf loop
    while (true) {
        const keys_pressed: []zeys.VK = try zeys.getCurrPressedKeys(@ptrCast(&vk_buf));
        
        // printing each key that is currently pressed
        for (keys_pressed) |key| {
            std.debug.print("{d}\n", .{@intFromEnum(key)});
            if (std.mem.eql(zeys.VK, keys_pressed, vk_compare_slice) != true) {
                const curr_char: u8 = zeys.getCharFromVkEnum(key) catch { continue; };
                std.debug.print("{c}", .{curr_char});
            }
        }
        vk_compare_slice.len = keys_pressed.len;
    }
}