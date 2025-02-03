const std = @import("std");
const zeys = @import("zeys");

/// Demonstrates automating key presses using zeys.
/// This program simulates opening Notepad and typing text, 
/// followed by pressing specific keys and repeating key presses.
pub fn main() !void {
    // Simulate pressing and releasing the Windows key to open the Start menu
    try zeys.pressAndReleaseKey(zeys.VK.VK_LWIN); // press Windows key
    std.time.sleep(std.time.ns_per_s); // wait 1s

    // Simulate typing "Notepad" into the Start menu search
    try zeys.pressKeyString("Notepad"); // Notice the capital letter 'N' is written out as a capital (SHIFT held w/ keypress)
    std.time.sleep(std.time.ns_per_s); // wait 1s

    // Simulate pressing ENTER to open Notepad
    try zeys.pressAndReleaseKey(zeys.VK.VK_RETURN); // press ENTER
    std.time.sleep(std.time.ns_per_s); // wait 1s

    // Simulate pressing and releasing number keys (0, 4, 9)
    try zeys.pressAndReleaseKey(zeys.VK.VK_0);
    std.time.sleep(std.time.ns_per_s); // wait 1s
    try zeys.pressAndReleaseKey(zeys.VK.VK_4);
    std.time.sleep(std.time.ns_per_s); // wait 1s
    try zeys.pressAndReleaseKey(zeys.VK.VK_9);
    std.time.sleep(std.time.ns_per_s); // wait 1s

    // Simulate pressing the 'A' key 50 times
    for (0..50) |i| { 
        _ = i;
        try zeys.pressAndReleaseKey(zeys.VK.VK_A);
    }
}