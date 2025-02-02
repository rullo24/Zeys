const std = @import("std");
const zeys = @import("zeys");
const print = std.debug.print;

pub fn main() !void {
    // setting allocator
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = gpa.allocator();
    defer _ = gpa.deinit();

    const keyboard_locale_hex_string: []const u8 = try zeys.getKeyboardLocaleIdAlloc(alloc);
    defer alloc.free(keyboard_locale_hex_string);
    std.debug.print("Your Keyboard Hex String: 0x{s}\n", .{keyboard_locale_hex_string});

    const keyboard_locale_human_string: []const u8 = try zeys.getKeyboardLocaleStringFromWinLocale(keyboard_locale_hex_string);
    std.debug.print("Your Keyboard: {s}\n", .{keyboard_locale_human_string});
}