# Zeys - A Zig Keyboard Module
Zeys provides a set of functions for simulating keyboard events, handling hotkeys, and interacting with the Windows API to manage keyboard inputs. It supports binding, unbinding, and triggering hotkeys, simulating key presses and releases, checking key states, and more. This module is intended for use in Windows-based applications.

## Current Operating System Support
| Platform | Support |
|----------|---------|
| Windows  | ✔       |
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
```

## Installation
To install zeys, simply the singular src file "zeys.zig" from this repo and clone it to your project repo. To include Zeys as a module in your Zig code, simply add the module in your build.zig file. 

### Installation - Example
```zig
const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimise = b.standardOptimizeOption(.{});

    // creating executable
    const exe = b.addExecutable(.{ 
        .name = "your_exd"
        .root_source_file = b.path("./relative_path_to_your_exe"),
        .target = target,
        .optimize = optimise,
    });

    // defining the Zeys keyboard library as a module
    const zeys_module = b.addModule("zeys", .{
        .root_source_file = b.path("../src/zeys.zig"),
    });

    // linking libraries to each executable
    exe.root_module.addImport("zeys", zeys_module); // adding the zeys code to the example
    exe.linkSystemLibrary("user32"); // not required but good practice (libs linked by extern "user32" near function src code)

    // creating an artifact (exe)
    b.installArtifact(exe);
}
```

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
For more example usage of the library, please check the ./example directory included in this repo. This explains in higher detail the intricacies of the project.

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

## Disclaimer
This module is provided as-is. I am not responsible for any misuse or unintended consequences that may result from using this module. Please use it responsibly and ensure you have proper safeguards in place before using any functions that block input or simulate key presses.