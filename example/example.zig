const std = @import("std");
const zeys = @import("zeys");

pub fn main() !void {
    // creating allocator for heap memory allocation
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = gpa.allocator();
    defer _ = gpa.deinit();

    _ = alloc;

    _ = zeys.getCurrKeyState(zeys.getVirtKeyConvU8(zeys.VK_ENUM.VK_A));
}