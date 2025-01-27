const std = @import("std");
const zeys = @import("zeys");

pub fn main() !void {
    // creating allocator for heap memory allocation
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = gpa.allocator();
    defer _ = gpa.deinit();

    _ = alloc;

    while (true) {
        if (zeys.isPressed(zeys.VK_ENUM.VK_A)) {
            _ = zeys.pressKeyDown(zeys.VK_ENUM.VK_Z);
            std.debug.print("pressed\n", .{});
            _ = zeys.releaseKey(zeys.VK_ENUM.VK_Z);
        }
    }
}
