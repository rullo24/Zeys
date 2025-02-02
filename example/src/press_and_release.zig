const std = @import("std");
const zeys = @import("zeys");
const print = std.debug.print;

pub fn main() !void {
    // opening notepad.exe
    try zeys.pressAndReleaseKey(zeys.VK.VK_LWIN); // press Windows key
    std.time.sleep(std.time.ns_per_s); // wait 1s
    try zeys.pressKeyString("Notepad"); // type in "notepad" --> notice the capital letter
    std.time.sleep(std.time.ns_per_s); // wait 1s
    try zeys.pressAndReleaseKey(zeys.VK.VK_RETURN); // press ENTER
    std.time.sleep(std.time.ns_per_s); // wait 1s

    // pressing and release showcase
    try zeys.pressAndReleaseKey(zeys.VK.VK_0);
    std.time.sleep(std.time.ns_per_s); // wait 1s
    try zeys.pressAndReleaseKey(zeys.VK.VK_0);
    std.time.sleep(std.time.ns_per_s); // wait 1s
    try zeys.pressAndReleaseKey(zeys.VK.VK_0);
    std.time.sleep(std.time.ns_per_s); // wait 1s

    for (0..50) |i| { // pressing 'a' x50
        _ = i;
        try zeys.pressAndReleaseKey(zeys.VK.VK_A);
    }
}