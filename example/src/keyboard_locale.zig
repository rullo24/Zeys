const std = @import("std");
const zeys = @import("zeys");
const print = std.debug.print;

/// Demonstrates retrieving and displaying the keyboard locale information.
/// This program fetches the keyboard locale ID in hexadecimal format and its corresponding human-readable string.
pub fn main() !void {
    // Initialize a general-purpose allocator
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = gpa.allocator();
    defer _ = gpa.deinit();

    // Retrieve the keyboard locale ID as a hex string
    const keyboard_locale_hex_string: []const u8 = try zeys.getKeyboardLocaleIdAlloc(alloc);
    defer alloc.free(keyboard_locale_hex_string);
    std.debug.print("Your Keyboard Hex String: 0x{s}\n", .{keyboard_locale_hex_string});

    // Convert the hex locale ID to a human-readable keyboard layout name
    const keyboard_locale_human_string: []const u8 = try zeys.getKeyboardLocaleStringFromWinLocale(keyboard_locale_hex_string);
    std.debug.print("Your Keyboard: {s}\n", .{keyboard_locale_human_string});
}