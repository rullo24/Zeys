const std = @import("std");
const zeys = @import("zeys");

/// Demonstrates binding hotkeys to functions using the zeys library.
/// This program binds different key combinations to execute functions that interact with custom structs.

/// === RELEVANT INFO ===
/// A `packed struct` is used when you need to create a struct where the fields are not aligned to typical memory boundaries. 
/// In most programming languages, structs have alignment constraints to optimize memory access. However, in some cases, you might need 
/// to work with data in a specific format that does not follow these standard alignment rules. This is where `packed struct` comes into play.
///
/// For example, `packed struct` is useful in low-level memory management tasks, such as reading from or writing to a memory-mapped hardware device.
/// It’s also commonly used when working with network protocols or file formats where the data is packed in a specific way that does not follow the system's natural alignment rules.
///
/// When creating a packed struct, Zig will not automatically insert padding between fields, which is typically done to ensure proper memory alignment.
/// However, when working with packed structs, be cautious about the potential for performance hits or errors due to misaligned memory access.
/// In this example, `test_struct_2` is a packed struct where fields are intentionally not aligned to 8-bit boundaries, making it essential to use special casting techniques to correctly handle the struct in memory.
/// NOTE: It is recommended that you work w/ byte-aligned data (i.e u8, u16, i32, u64, etc.) to avoid this issue.

/// The `anyopaque` type in Zig is a generic pointer that represents a "pointer to any type" and is used to pass around data when the 
/// specific type is not known at compile time. This is similar to using `void*` in C, but with more control and safety in Zig's type system.
/// It allows you to handle arbitrary data types in a flexible manner.
///
/// In this example, `args` is a pointer of type `*anyopaque`, meaning it can point to any kind of struct or data. The purpose of using `anyopaque` 
/// here is to allow the hotkey functions to handle different structs dynamically, regardless of their exact type. In practice, this is useful when 
/// you want to write a function that can work with a variety of data structures without needing to know the exact types ahead of time.
///
/// The `anyopaque` type essentially acts as a placeholder for an unknown or flexible data type, enabling generic function calls while maintaining Zig's safety checks.
/// NOTE: Due to the ambiguous nature of the data that is parsed into args, poorly aligned values can cause runtime panics.
/// Safety mechanisms have not yet been implemented for this, so please ensure that the arguments you parse are aligned (recommended to use byte-aligned variables)

/// In Zig, the `@alignCast` function is used to ensure that the data is properly aligned in memory according to the alignment requirements 
/// of the type you're casting to. Misaligned data can result in inefficient memory access or even runtime errors on some architectures. 
/// `@alignCast` adjusts the memory layout of the data to ensure it adheres to the alignment constraints of the target type.
///
/// The `@ptrCast` function is used to cast a pointer from one type to another. In this case, we're casting a pointer from `*anyopaque` 
/// (a generic pointer type) to a pointer of the specific type `*test_struct_2` or `*test_struct_3`. This is necessary because the data 
/// we pass around as `anyopaque` could be any struct, and we need to convert it back to its specific type before accessing the fields.
/// 
/// It's important to always use `@alignCast` before `@ptrCast` in this case because Zig requires the data to be properly aligned for the 
/// target type. If you skip `@alignCast`, and the data is not aligned correctly, attempting to cast it with `@ptrCast` will result in a runtime error.
///
/// In short:
/// - `@alignCast` ensures that the memory is aligned correctly for the target type.
/// - `@ptrCast` safely converts the pointer to the correct type, so you can work with the data as expected.

/// Simple struct that is byte-aligned (using default alignment) --> does not require "packed struct" due to default packing
const test_struct_1 = struct {
    inte: i32 = 400,
    third: u64 = 10000000,
    second: u16 = 50,
};

/// Packed struct where fields are not aligned to byte boundaries (e.g., u39 and u2)
/// Packing is necessary to handle non-byte-aligned data (to work with *anyopaque type for argument parsing)
const test_struct_2 = packed struct {
    first: u8,
    second: u39,
    third: u2
};

/// Simple struct that is byte-aligned (using default alignment)
/// The fields are arrays of u8 (which are still byte-aligned)
const test_struct_3 = struct {
    first: [4]u8,
    second: [3]u8,
    third: [7]u8,
};

/// Function to handle hotkey events for test_struct_1
// NOTE: parse in arguments as a "*void" equivalent struct --> even if there are no arguments
// This function doesn’t need any data passed, so an empty struct is parsed.
fn tester_func_1(args: *anyopaque) void {
    // const p_struct_1: *test_struct_1 = @ptrCast(@alignCast(args));
    // NOTE: Despite being done so in the other two tester funcs, the above code (const p_struct_1 should not be decommmented)
    // This is because alignment must exist between the parsed struct (anonymous) and the casted struct (*test_struct_1)
    // In this case, the size of the parsed struct (size=0) does not align with the test_struct_1 type so would cause a panic if we were to try and cast to a *test_struct_1 from a anonymous struct
    _ = args;
    std.debug.print("You're working in tester_func_1() :)\n", .{});
}

/// Function to handle hotkey events for test_struct_2
// NOTE: parse in arguments as a "*void" equivalent struct --> pointing to the struct where the arguments are held
fn tester_func_2(args: *anyopaque) void {
    // NOTE: @alignCast() --> aligns the parsed data w/ a test_struct_2 (will panic if not byte-aligned)
    // NOTE: @ptrCast() --> Casting from *anyopaque --> *test_struct_2 
    const p_struct_2: *test_struct_2 = @ptrCast(@alignCast(args)); // @alignCast required before @ptrCast ALWAYS
    std.testing.expect(p_struct_2.second == 300000) catch std.debug.print("FAILED\n", .{});
    std.testing.expect(p_struct_2.second != p_struct_2.third) catch std.debug.print("FAILED\n", .{});
    std.testing.expect(p_struct_2.first == 'h') catch std.debug.print("FAILED\n", .{});
    std.debug.print("SUCCESSFUL RUN\n", .{});
}

/// Function to handle hotkey events for test_struct_3
// NOTE: parse in arguments as a "*void" equivalent struct --> pointing to the struct where the arguments are held
fn tester_func_3(args: *anyopaque) void {
    // NOTE: @alignCast() --> aligns the parsed data w/ a test_struct_3 (will panic if not byte-aligned)
    // NOTE: @ptrCast() --> Casting from *anyopaque --> *test_struct_3
    const p_struct_3: *test_struct_3 = @ptrCast(@alignCast(args)); // @alignCast required before @ptrCast ALWAYS
    std.debug.print("{s} {s} {s}\n", .{ p_struct_3.first, p_struct_3.second, p_struct_3.third });
}

/// Main function to set up hotkey bindings and execute callbacks
pub fn main() !void {
    // EXAMPLE 1: Binding Z + CTRL + SHIFT to tester_func_1
    std.debug.print("Press Z + CTRL + SHIFT to run tester_func_1\n", .{});
    std.debug.print("Press 0 to move to the next example\n", .{});
    // var tester_1: test_struct_1 = .{};
    try zeys.bindHotkey(&[_]zeys.VK{ zeys.VK.VK_Z, zeys.VK.VK_CONTROL, zeys.VK.VK_SHIFT, }, 
                            &tester_func_1, 
                            @constCast(&.{}),   // need to parse an empty struct for no arguments | NOTE: @constCast() --> allows const to be inferred as var (mutable) when parsed
                            false); // false means the hotkey doesn't repeat on key hold
    try zeys.waitUntilKeysPressed( &[_]zeys.VK{ zeys.VK.VK_0, });
    try zeys.unbindHotkey( &[_]zeys.VK{ zeys.VK.VK_Z, zeys.VK.VK_CONTROL, zeys.VK.VK_SHIFT, });

    // EXAMPLE 2: Binding B to tester_func_2
    std.debug.print("Press B to run tester_func_1\n", .{});
    std.debug.print("Press 1 to move to the next example\n", .{});
    std.debug.print("Try and press Z + CTRL + SHIFT again. It won't work because we have unbinded it\n", .{});
    
    // NOTE: The struct example_2 is a "packed struct", avoid alignment issues (due to the struct values not being 8-bit [1-byte] aligned)
    // NOTE: When creating structs that are not byte-aligned (8-bits), ensure that the obj is created before being referenced. 
    // Creating an obj via the anonymous struct syntax (&.{} in func arg) removes the padding effect of a "packed struct"
    // For more information on packed structs (and when to use), refer to relevant Ziglang packed struct documentation - "https://ziglang.org/documentation/master/#packed-struct"
    const example_2: test_struct_2 = .{ .first = 'h', .second = 300000, .third = 0x2 };
    try zeys.bindHotkey(&[_]zeys.VK{ zeys.VK.VK_B, zeys.VK.UNDEFINED, zeys.VK.UNDEFINED, zeys.VK.UNDEFINED, zeys.VK.UNDEFINED }, 
                            &tester_func_2, 
                            @constCast(&example_2), // casting struct marked as "const" as a mutable (var) *anyopaque ptr
                            true); // bool at end of bindHotkey() call is for repeating the callback after holding the key
    try zeys.waitUntilKeysPressed(&[_]zeys.VK{ zeys.VK.VK_1 });

    // EXAMPLE 3: Binding C + LCTRL to tester_func_3
    std.debug.print("Press C + LCTRL (or RCTRL as modifiers are treated the same in Windows hotkeys) to run tester_func_1\n", .{});
    std.debug.print("Press 2 to end the examples\n", .{});
    std.debug.print("Try and press B. This hotkey will still function because we haven't unbinded it\n", .{});

    // IMPORTANT NOTE: In Windows hotkey modifiers, left and right modifier keys (e.g., LCTRL and RCTRL) are treated as equivalent.   
    var tester_3: test_struct_3 = undefined;
    @memcpy(&tester_3.first, "hey,"); // @memcpy should be used w/ caution (to prevent panic)
    @memcpy(&tester_3.second, "how");
    @memcpy(&tester_3.third, "are you");
    try zeys.bindHotkey( &[_]zeys.VK{ zeys.VK.VK_C, zeys.VK.VK_LCONTROL, },
                            &tester_func_3, 
                            @ptrCast(&tester_3), // casting struct marked as a var (mutable) as a *anyopaque ptr
                            true); 
    try zeys.waitUntilKeysPressed( &[_]zeys.VK{zeys.VK.VK_2, zeys.VK.UNDEFINED, });
}