const std = @import("std");
const zeys = @import("zeys");
const print = std.debug.print;

// pressing a singular key --> displaying in console stdin
pub fn main() !void {
    // var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    // const alloc = gpa.allocator();
    // defer _ = gpa.deinit();

    std.time.sleep(std.time.ns_per_s * 2);

    try zeys.pressKeyString("Testing101");

    // zeys.zeysInfWait();

    return;
}