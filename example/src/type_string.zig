const std = @import("std");
const zeys = @import("zeys");
const print = std.debug.print;

pub fn main() !void {
    try zeys.pressAndReleaseKey(zeys.VK.VK_LWIN); // press Windows key
    std.time.sleep(std.time.ns_per_s); // wait 1s

    try zeys.pressKeyString("Notepad"); // type in "notepad" --> notice the capital letter
    std.time.sleep(std.time.ns_per_s); // wait 1s
    try zeys.pressAndReleaseKey(zeys.VK.VK_RETURN); // press ENTER

    std.time.sleep(std.time.ns_per_s); // wait 1s
    try zeys.pressKeyString("This is a Test\n $$$#!#((%))\tTOP");
}