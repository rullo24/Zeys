const std = @import("std");
const zeys = @import("zeys");

/// Demonstrates automating key presses using zeys.
/// This program simulates opening Notepad and typing text.
pub fn main() !void {
    // Simulate pressing and releasing the Windows key to open the Start menu
    try zeys.pressAndReleaseKey(zeys.VK.VK_LWIN); // press Windows key
    std.time.sleep(std.time.ns_per_s); // wait 1s

    // Simulate typing "Notepad" into the Start menu search
    try zeys.pressKeyString("Notepad"); // type in "notepad" --> notice the capital letter
    std.time.sleep(std.time.ns_per_s); // wait 1s

    // Simulate pressing ENTER to open Notepad
    try zeys.pressAndReleaseKey(zeys.VK.VK_RETURN); // press ENTER
    std.time.sleep(std.time.ns_per_s); // wait 1s

    // Simulate typing text into Notepad, including special characters and a tab
    try zeys.pressKeyString("This is a Test\n $$$#!#((%))\tTOP");
}