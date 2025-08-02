# Zeys - A Zig Keyboard Module

Zeys provides a set of functions for simulating keyboard events, handling hotkeys, and interacting with the Windows API to manage keyboard inputs. It supports binding, unbinding, and triggering hotkeys, simulating key presses and releases, checking key states, and more. This module is intended for use in Windows-based applications.

## Current Operating System Support

| Platform | Support |
| -------- | ------- |
| Windows  | ✔      |
| Linux    | ❌      |
| Mac      | ❌      |

NOTE: Currently, the module only supports Windows. Linux support will be considered in future updates (if people would like this).

## Features

- Simulate Key Presses: Simulate pressing and releasing keys using the pressAndReleaseKey() function.
- Hotkey Management: Bind and unbind hotkeys that trigger functions when pressed.
- Blocking User Input: Block and unblock user input (keyboard and mouse) system-wide.
- Key State Checking: Check whether a key is pressed or toggled (e.g., Caps Lock).
- Locale Information: Retrieve the current keyboard locale and map it to a human-readable format.
- Custom Callbacks: Set up custom functions that will be executed when specific keys or hotkeys are pressed.

## Installation

NOTE: At the time of Zeys v1.1.0's release, this code works on Zig v0.13.0 (the latest release).

Thanks to SuSonicTH, I have had some help in updating this repo (v1.1.0) to allow for it to be downloaded via Zig's built-in package manager (zon).

To use Zeys in your project, simply follow the process below:

1. Fetch the Zeys repo from within one of the project's folders (must have a build.zig). This will automatically add the dependency to your project's build.zig.zon file (or create one if this currently does not exist).
   - An example for importing Zeys v1.1.0 is shown below

```zig
zig fetch --save "https://github.com/rullo24/Zeys/archive/refs/tags/v1.1.0.tar.gz"
```

2. Add the Zeys dependency to your build.zig file
   - An example is shown below (build.zig)

```zig
const std = @import("std");

pub fn build(b: *std.Build) void {
    const optimise = b.standardOptimizeOption(.{});
    const target = b.standardTargetOptions(.{});

    const zeys = b.dependency("Zeys", .{
        .target = target,
        .optimize = optimise,
    });

    const exe = b.addExecutable(.{
        .name = "tester",
        .root_source_file = b.path("test_zeys.zig"),
        .optimize = optimise,
        .target = target,
    });

    exe.root_module.addImport("zeys", zeys.module("zeys"));
    b.installArtifact(exe);
}
```

3. Import the Zeys module at the top of your code using the "@import" method
   - An example is shown below (test_zeys.zig)

```zig
const std = @import("std");
const zeys = @import("zeys");

pub fn main() void {
    while (true) {
        if (zeys.isPressed(zeys.VK.VK_A) == true) {
            std.debug.print("ON\n", .{});
        }
    }

    return;
}
```

## API

```zig
/// Binds a hotkey to a Windows WM_HOTKEY message.
/// 
/// - `keys`: The virtual keys to bind.
/// - `p_func`: The callback function to invoke when the hotkey is triggered.
/// - `p_args_struct`: The arguments to pass to the callback.
/// - `repeat`: Whether the hotkey should repeat more than once when held down.
bindHotkey(keys: []const VK, p_func: *const fn (*anyopaque) void, p_args_struct: *?anyopaque, repeat: bool) !void

/// Unbinds a hotkey, preventing the associated WM_HOTKEY messages from being sent.
/// 
/// - `keys`: The virtual keys of the hotkey to unbind.
unbindHotkey(keys: []const VK) !void

/// Simulates an infinite wait loop while calling callback functions when hotkeys are triggered.
zeysInfWait() void

/// Waits for the specified keys to be pressed (simulates a while (not_pressed)) and triggers the corresponding hotkey callback functions.
/// 
/// - `virt_keys`: The virtual keys to wait for before passing over this function
waitUntilKeysPressed(virt_keys: []const VK) !void

/// Returns the virtual keys (VK) that are currently pressed (globally).
///
/// - `vk_buf`: A mutable buffer slice of type `VK` to store the keys detected as pressed. The buffer must be at least 255 elements long.
///
/// Returns a slice of Zeys virtual keys.
getCurrPressedKeys(vk_buf: []VK) ![]VK

/// Checks if the specified key is currently pressed.
/// 
/// - `virt_key`: The virtual key to check.
/// 
/// Returns true if the key is pressed, false otherwise.
isPressed(virt_key: VK) bool

/// Checks if the specified toggle key is active (e.g., Caps Lock, Num Lock).
/// 
/// - `virt_key`: The toggle key to check.
/// 
/// Returns true if the toggle key is active, false otherwise.
isToggled(virt_key: VK) !bool

/// Simulates pressing and releasing a key once, with a 1ms delay to avoid undefined behavior.
/// 
/// - `virt_key`: The virtual key to press and release.
pressAndReleaseKey(virt_key: VK) !void

/// Simulates pressing a sequence of keys corresponding to the characters in the provided string.
/// 
/// - `str`: The string of characters to simulate as key presses.
pressKeyString(str: []const u8) !void

/// Checks if the specified key is a modifier key (e.g., Ctrl, Shift, Alt).
/// 
/// - `virt_key`: The key to check.
/// 
/// Returns true if the key is a modifier, false otherwise.
keyIsModifier(virt_key: VK) bool

/// Retrieves the current keyboard's locale ID (hexadecimal string).
/// 
/// - `alloc`: The memory allocator to use for the locale ID string.
/// 
/// Returns the keyboard locale ID.
getKeyboardLocaleIdAlloc(alloc: std.mem.Allocator) ![]u8

/// Converts a Windows locale ID (hex string) to a human-readable string.
/// 
/// - `u8_id`: The locale ID in hexadecimal string format.
/// 
/// Returns the keyboard layout string corresponding to the locale ID.
getKeyboardLocaleStringFromWinLocale(u8_id: []const u8) ![]const u8

/// Blocks all user input (keyboard and mouse) system-wide. Requires admin privileges.
blockAllUserInput() !void

/// Unblocks all user input (keyboard and mouse) system-wide. Requires admin privileges.
unblockAllUserInput() !void

/// Converts a virtual key enum (`VK`) to its corresponding `u8` representation.
///
/// - `virt_key_enum`: The virtual key enum value to convert.
getCharFromVkEnum(virt_key_enum: VK) !u8

/// Converts a `c_short` integer value to its corresponding virtual key enum (`VK`).
///
/// - `vk_short`: The `c_short` integer representing a virtual key code.
getVkEnumFromCShort(vk_short: c_short) !VK

/// Retrieves the virtual key code corresponding to the given ASCII character.
///
/// - `ex_char`: An ASCII character (`u8`).
getVkFromChar(ex_char: u8) !VK
```

## Important Background Information - Virtual Keys (VK)

Virtual keys are constants used by the Windows API to represent keyboard keys. These constants are part of the enum(c_short) declaration in Zeys and correspond to both standard and special keys i.e. function keys (F1-F12), numeric keypad keys, and modifier keys (e.g., Shift, Ctrl, Alt).

This enum allows for more manageable code when working with keyboard inputs, as you can use meaningful names like VK_A, VK_RETURN (enter), and VK_SHIFT instead of raw numeric values. Virtual keys are essential for simulating key presses and managing hotkeys in the Zeys module.

List of Common Virtual Keys

- Standard Keys: VK_A, VK_B, VK_C, ..., VK_Z
- Numeric Keys: VK_0, VK_1, VK_2, ..., VK_9
- Function Keys: VK_F1, VK_F2, VK_F3, ..., VK_F24
- Modifiers: VK_SHIFT, VK_CONTROL, VK_MENU, VK_LSHIFT, VK_RSHIFT
- Navigation Keys: VK_UP, VK_DOWN, VK_LEFT, VK_RIGHT
- Toggle Keys: VK_CAPITAL (Caps Lock), VK_NUMLOCK, VK_SCROLL
- More VKs (view zeys.zig)

### Virtual Keys - Example Usage

Here’s how you can use the virtual keys in Zeys to simulate key presses or bind hotkeys:

```zig
// Simulating a key press of the "A" key
pressAndReleaseKey(zeys.VK.VK_A); // Simulates pressing and releasing the 'A' key

// Binding a hotkey to Ctrl+Shift+Z
try zeys.bindHotkey( &[_]zeys.VK{ zeys.VK.VK_Z, zeys.VK.VK_CONTROL, zeys.VK.VK_SHIFT, }, &tester_func_1, @constCast(&.{}), false);
```

These virtual keys are used throughout the Zeys module for functions like bindHotkey(), pressAndReleaseKey(), isPressed(), and more. They help to ensure that the module can interact with the system in a way that aligns with Windows' key-coding conventions.

## Usage

### Binding a Hotkey

To bind a hotkey, use the bindHotkey() function. This will associate a specific combination of keys with a function to be called when the hotkey is pressed.

#### Binding a Hotkey - Example

```zig
fn tester_func_1(args: *anyopaque) void {
    _ = args;
    std.debug.print("You're working in tester_func_1() :)\n", .{});
}

pub fn main() {
    std.debug.print("Press Z + CTRL + SHIFT to run tester_func_1\n", .{});
    std.debug.print("Press 0 to move to the next example\n", .{});
    // var tester_1: test_struct_1 = .{};
    try zeys.bindHotkey( &[_]zeys.VK{ zeys.VK.VK_Z, zeys.VK.VK_CONTROL, zeys.VK.VK_SHIFT, }, 
                            &tester_func_1, 
                            @constCast(&.{}), // need to parse an empty struct for no arguments --> casting struct to pointer
                            false);
    try zeys.waitUntilKeysPressed( &[_]zeys.VK{ zeys.VK.VK_0, });
    try zeys.unbindHotkey( &[_]zeys.VK{ zeys.VK.VK_Z, zeys.VK.VK_CONTROL, zeys.VK.VK_SHIFT, });
}
```

### Unbinding a Hotkey

To unbind a hotkey, use the unbindHotkey() function and provide the same key combination used during binding.

#### Unbinding a Hotkey - Example

```zig
unbindHotkey( &[_]zeys.VK{ zeys.VK.VK_B, } );
```

### Simulating a Key Press

To simulate a key press, you can use the pressAndReleaseKey() function.

#### Simulating a Key Press - Example

```zig
pressAndReleaseKey(zeys.VK.VK_A); // Simulate pressing and releasing the 'A' key
```

### Blocking User Input

To block all user input (keyboard and mouse), use the blockAllUserInput() function.

#### Blocking User Input - Example

```zig
blockAllUserInput();
```

## More Examples

For more example usage of the library, please check the *./example* directory included in this repo. This folder explains in higher detail the intricacies of the project.

## Windows API Functions Used

This module relies on several Windows API functions to interact with the system's keyboard and input functionality. Some of the key functions used include:

- RegisterHotKey
- SendInput
- GetAsyncKeyState
- BlockInput
  For more information about these functions, refer to the Windows API documentation.

## Error Handling

Zeys uses Zig's built-in error handling for common failure scenarios, such as:

- Too many keys provided for a hotkey binding.
- Failed to register or unregister a hotkey.
- Issues with sending key inputs or blocking/unblocking input.
- And more

## License

This module is provided as-is. I am not responsible for any misuse or unintended consequences that may result from using this module. Please use it responsibly and ensure you have proper safeguards in place before using any functions that block input or simulate key presses.

This project is licensed under the MIT License - see the LICENSE file for details.
