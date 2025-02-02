const std = @import("std");
const zeys = @import("zeys");

/// input blocking is used to stop the user from interacting w/ the system temporarily
/// NOTE: input blocking requires Admin privileges
pub fn main() !void {
    // blocking, waiting for 3 seconds and then unblocking keyboard input
    try zeys.blockAllUserInput();
    std.time.sleep(std.time.ns_per_s * 3);

    try zeys.unblockAllUserInput();
    std.time.sleep(std.time.ns_per_s * 3);
}