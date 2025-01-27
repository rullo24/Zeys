const std = @import("std");
const zeys = @import("zeys");

// pressing a singular key --> displaying in console stdin
pub fn main() !void {
    const read_buf: [1024]u8 = std.mem.zeroes(1024); // creating buffer
    const stdin = std.io.getStdIn().reader(); // creating a reader object

    try zeys.pressKey(zeys.VK_ENUM.VK_0); // will show when stdin is unblocked (next line)
    _ = try stdin.readUntilDelimiter(read_buf, '\n'); // showing stdin (with pressed key)

}