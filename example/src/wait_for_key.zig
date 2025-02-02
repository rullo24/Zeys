const std = @import("std");
const zeys = @import("zeys");
const print = std.debug.print;

pub fn main() !void {
    // array of size 5 used to accomodate for max num of keys that can be set as a hotkey
    // i.e. basekey + SHIFT_MODIFIER + CTRL_MODIFIER + ALT_MODIFIER + WIN_MODIFIER

    // IMPORTANT NOTE: must pack the array with UNDEFINED for non-used keys --> func takes [5]zeys.VK as argument
    std.debug.print("Step 1: Waiting for A Key Press\n", .{});
    // const packed_virt_keys_1 = try zeys.packVirtKeyArray( &[_]zeys.VK{ zeys.VK.VK_A } );
    // try zeys.waitUntilKeysPressed( &packed_virt_keys_1 );
    // std.debug.print("A Pressed\n", .{});

    // std.debug.print("Step 2: Waiting for B + CTRL Key Press\n", .{});
    // const packed_virt_keys_2 = [_]zeys.VK{ zeys.VK.VK_B, zeys.VK.VK_CONTROL, zeys.VK.UNDEFINED, zeys.VK.UNDEFINED, zeys.VK.UNDEFINED };
    // try zeys.waitUntilKeysPressed( &packed_virt_keys_2 );
    // std.debug.print("B + CTRL Pressed\n", .{});

    // std.debug.print("Step 3: Waiting for C + SHIFT + LWIN Key Press\n", .{});
    // const packed_virt_keys_3 = try zeys.packVirtKeyArray( &[_]zeys.VK{ zeys.VK.VK_C, zeys.VK.VK_SHIFT, zeys.VK.VK_LWIN });
    // try zeys.waitUntilKeysPressed( &packed_virt_keys_3 );
    // std.debug.print("C + SHIFT + LWIN Pressed\n", .{});

    // zeys.packVirtKeyArray(.{22, 44, 33.0}) catch {
    //     std.debug.print("You can't pack w/ datatypes other than zeys.VK", .{});
    // };
}