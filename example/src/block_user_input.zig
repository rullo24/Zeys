const std = @import("std");
const zeys = @import("zeys");

/// Demonstrates temporarily blocking and unblocking user input.
/// This prevents the user from interacting with the system for a short duration.
/// 
/// NOTE: Blocking input requires administrative privileges.
pub fn main() !void {
    // Block all user input (keyboard and mouse) 
    try zeys.blockAllUserInput();
    
    // Keep input blocked for 3 seconds (3 billion nanoseconds)
    std.Thread.sleep(std.time.ns_per_s * 3);

    // Unblock user input, restoring normal system interaction
    try zeys.unblockAllUserInput();
    
    // Wait for another 3 seconds before the program exits
    std.Thread.sleep(std.time.ns_per_s * 3);
}