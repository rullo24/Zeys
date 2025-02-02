// =======================
// === STD ZIG IMPORTS ===

const std = @import("std");
const c = std.c;
const windows = std.os.windows;

// === STD ZIG IMPORTS ===
// =======================

// =================================
// === WINDOWS API FUNCTIONALITY ===

const KEYEVENTF_EXTENDEDKEY = 0x0001; // for including non-alphanumeric keys
const KEYEVENTF_KEYUP = 0x0002; // for releasing a key
const INPUT_KEYBOARD = 0x01; // setting input send from keyboard
const WM_KEYUP = 0x0101; 
const WM_KEYDOWN = 0x0100; 
const WM_HOTKEY = 0x0312; 

extern "user32" fn GetAsyncKeyState(vKey: c_int) c_short;
extern "user32" fn BlockInput(block_flag: bool) windows.BOOL;
extern "user32" fn GetForegroundWindow() windows.HWND;
extern "user32" fn VkKeyScanA(ch: u8) c_short;
extern "user32" fn SendInput(cInputs: c_uint, pInputs: *const INPUT, cbSize: c_int) c_uint;
extern "user32" fn SendMessage(hWnd: windows.HWND, Msg: c_uint, wParam: windows.WPARAM, lParam: windows.LPARAM) windows.LRESULT;
extern "user32" fn GetKeyboardLayoutNameA(pwszKLID: windows.LPSTR) windows.BOOL;
extern "user32" fn GetMessageA(lpMsg: *MSG, hWnd: ?windows.HWND, wMsgFilterMin: windows.UINT, wMsgFilterMax: windows.UINT) windows.BOOL;
extern "user32" fn PeekMessageA(lpMsg: *MSG, hWnd: ?windows.HWND, wMsgFilterMin: windows.UINT, wMsgFilterMax: windows.UINT, wRemoveMsg: windows.UINT) windows.BOOL;
extern "user32" fn RegisterHotKey(hWnd: ?windows.HWND, id: c_uint, fsModifiers: windows.UINT, vk: windows.UINT) windows.BOOL;
extern "user32" fn UnregisterHotKey(hWnd: ?windows.HWND, id: c_int) windows.BOOL;
extern "user32" fn GetLastError() windows.DWORD;

// === WINDOWS API FUNCTIONALITY ===
// =================================

// ==========================
// === EXTERN STRUCT DEFS ===

const MOUSEINPUT = extern struct {
    dx: windows.LONG = 0x0,
    dy: windows.LONG = 0x0,
    mouseData: windows.DWORD = 0x0,
    dwFlags: windows.DWORD = 0x0,
    time: windows.DWORD = 0x0,
    dwExtraInfo: windows.ULONG_PTR = 0x0,
};

const KEYBDINPUT = extern struct {
    wVk: windows.WORD = 0x0,
    wScan: windows.WORD = 0x0,
    dwFlags: windows.DWORD = 0x0,
    time: windows.DWORD = 0x0,
    dwExtraInfo: windows.ULONG_PTR = 0x0,
};

const HARDWAREINPUT = extern struct {
    uMsg: windows.DWORD = 0x0,
    wParamL: windows.WORD = 0x0,
    wParamH: windows.WORD = 0x0,
};

const DUMMYUNIONNAME = extern union {
    mi: MOUSEINPUT, // .init zeros the struct
    ki: KEYBDINPUT, // .init zeros the struct
    hi: HARDWAREINPUT, // .init zeros the struct
};

const INPUT = extern struct {
    input_type: windows.DWORD = 0x0,
    DUMMYUNIONNAME: DUMMYUNIONNAME,
};

const MSG = extern struct {
    hwnd: windows.HWND,
    message: windows.UINT,
    wParam: windows.WPARAM,
    lParam: windows.LPARAM,
    time: windows.DWORD,
    pt: windows.POINT,
    lPrivate: windows.DWORD,
};

// === EXTERN STRUCT DEFS ===
// ==========================

// =========================
// === CUSTOM STRUCTURES ===

const WIN32_CALLBACK_TYPES = enum(u8) {
    HOTKEY = 0x01,
    HOOK = 0x02,
};

const Hotkey_Hook_Callback = struct { // used in Msg thread (for calling callback functions)
    id: c_int,   
    vk_arr: [3]VK,
    callback: *const anyopaque,
    args: *anyopaque,
    back_type: WIN32_CALLBACK_TYPES, 
};

// === CUSTOM STRUCTURES ===
// =========================

// ===================
// === GLOBAL VARS ===

const MAX_NUM_HOTKEY_HOOK_KEYS: usize = 10;
var run_threads_flag: bool = true;
pub var callback_thread: ?std.Thread = null;
var hotkeys_arr: [MAX_NUM_HOTKEY_HOOK_KEYS]Hotkey_Hook_Callback = undefined;
var hotkeys_i_opt: ?usize = null;
var hook_arr: [MAX_NUM_HOTKEY_HOOK_KEYS]Hotkey_Hook_Callback = undefined;
var hook_i_opt: ?usize = null;

// === GLOBAL VARS ===
// ===================

// ========================
// === PUBLIC FUNCTIONS ===

// binding a hotkey --> hotkey does not bind if another hotkey w/ these keys already exists 
pub fn bindHotkey(keys: [3]VK, p_func: *const fn (*anyopaque) void, p_args_struct: *anyopaque, repeat: bool) !void {
    // init necessary vars
    var fsModifiers: windows.UINT = 0x0; // init w/o any modifiers
    if (repeat != true) fsModifiers = fsModifiers | 0x4000; // MOD_NOREPEAT --> Changes the hotkey behavior so that the keyboard auto-repeat does not yield multiple hotkey notifications.
    var base_key_opt: ?windows.UINT = null; // virtual key of the non-modifier key

    // adding modifiers to fsModifiers param --> NOTE: RegisterHotKey treats L/R modifiers as equal (use hook for individuals)
    for (keys) |key| {
        switch (key) {
            VK.UNDEFINED => continue, // move over these (treat them as empty)
            VK.VK_MENU, VK.VK_LMENU, VK.VK_RMENU => fsModifiers = (fsModifiers | 0x0001), // ALT modifier bitwise OR
            VK.VK_CONTROL, VK.VK_LCONTROL, VK.VK_RCONTROL => fsModifiers = (fsModifiers | 0x0002), // CTRL modifier bitwise OR
            VK.VK_SHIFT, VK.VK_LSHIFT, VK.VK_RSHIFT => fsModifiers = (fsModifiers | 0x0004), // SHIFT modifier bitwise OR
            VK.VK_LWIN, VK.VK_RWIN => fsModifiers = (fsModifiers | 0x0008), // WIN modifier bitwise OR
            else => {
                if (base_key_opt != null) return error.Multiple_Non_Modifier_Keys_Provided;
                const base_key_c_short: c_short = @intFromEnum(key);
                base_key_opt = @intCast(base_key_c_short); 
            }
        }
    }

    // checking if a basekey was provided --> err if not
    if (base_key_opt == null) return error.No_Valid_Basekey;
    const base_key: windows.UINT = base_key_opt.?;

    // bounds checking global hotkeys slice
    var hotkeys_i: usize = 0; // init hotkey index
    if (hotkeys_i_opt) |hotkeys_slice_i| {
        if (hotkeys_slice_i >= MAX_NUM_HOTKEY_HOOK_KEYS) return error.Already_Filled_Hotkeys_Array; // bounds checking
        hotkeys_i = hotkeys_slice_i + 1; // incrementing index count (if possible)
    } 

    // registering the hotkey using the win32 API syscall
    const new_hotkey_id: c_uint = @intCast(hotkeys_i + 1); // HOTKEY ID == index + 1
    const hotkey_set: windows.BOOL = RegisterHotKey(null, new_hotkey_id, fsModifiers, base_key); // uses current thread handle where NULL
    if (hotkey_set == 0) return error.Could_Not_Reg_Hotkey; // error if failed to set hotkey (already used somewhere else in the system?)

    // adding to the slice that tracks all callbacks
    if (hotkeys_i > hotkeys_arr.len) return error.Hotkeys_Index_Too_Large;
    hotkeys_arr[hotkeys_i] = Hotkey_Hook_Callback { 
        .id = @intCast(new_hotkey_id),
        .vk_arr = keys,
        .callback = @ptrCast(p_func),
        .args = p_args_struct,
        .back_type = .HOTKEY,
    }; 
    hotkeys_i_opt = hotkeys_i; // upadating hotkey slice index tracker var
}

// freeing memory associated w/ a hotkey bind
pub fn unbindHotkey(keys: [3]VK) !void {
    // iterating over slice until keys are found
    var hotkey_id: c_int = -1;
    for (hotkeys_arr) |hotkey_struct| {
        if (std.meta.eql(hotkey_struct.vk_arr, keys)) {
            hotkey_id = hotkey_struct.id; // grabbing ID for win32 unbind func
            break; // move out of for loop once found
        }
    }
    if (hotkey_id < 0) return error.Could_Not_Find_Hotkey_ID;

    // unregister based on ID that is provided in hotkey specifying
    const unreg_res: windows.BOOL = UnregisterHotKey(null, hotkey_id);
    if (unreg_res == 0) return error.Failed_To_Unregister_Hotkey;
}

// simulates a while (true) {} without high CPU usage --> also provides callback func calls
pub fn zeysInfWait() void {
    var msg: MSG = undefined;
    while (true) {
        const msg_res: bool = (GetMessageA(&msg, null, 0x0, 0x0) != 0); // pushing recv'd message into "msg" buf
        if (msg_res == false) { // couldn't get msg --> error occurred (end thread)
            return;
        }
    
        // responding to a successful hotkey recv
        if (msg.message == WM_HOTKEY) {
            // checking if the hotkey is one of the hotkeys that have been activated here --> iterate
            const hotkey_id: windows.WPARAM = msg.wParam;
            const i_hotkey: usize = hotkey_id - 1; 
            if (hotkeys_i_opt == null) return;
            if (i_hotkey > hotkeys_i_opt.?) return;
            
            // grabbing the callback struct
            const hotkey: Hotkey_Hook_Callback = hotkeys_arr[i_hotkey];
            const callback_func: *const fn (args: *anyopaque) void = @ptrCast(hotkey.callback);
            callback_func(hotkey.args);
        }
    }
}

// simulates a while (true) {} without high CPU usage but passes when a certain key is pressed
pub fn waitUntilKeysPressed(virt_keys: [3]VK) !void {
    var msg: MSG = undefined;
    var leave_flag: bool = false;

    try bindHotkey(virt_keys, _trueBoolCallback, &leave_flag, false);

    while (leave_flag == false) {
        const msg_res: bool = (GetMessageA(&msg, null, 0x0, 0x0) != 0); // pushing recv'd message into "msg" buf
        if (msg_res == false) { // couldn't get msg --> error occurred (end thread)
            return;
        }

        // responding to a successful hotkey recv
        if (msg.message == WM_HOTKEY) {
            // checking if the hotkey is one of the hotkeys that have been activated here --> iterate
            const hotkey_id: windows.WPARAM = msg.wParam;
            const i_hotkey: usize = hotkey_id - 1; 
            if (hotkeys_i_opt == null) return;
            if (i_hotkey > hotkeys_i_opt.?) return;
            
            // grabbing the callback struct
            const hotkey: Hotkey_Hook_Callback = hotkeys_arr[i_hotkey];
            const callback_func: *const fn (args: *anyopaque) void = @ptrCast(hotkey.callback);
            callback_func(hotkey.args);
        }
    }   
}

// checking if a key is currently activated
pub fn isPressed(virt_key: VK) bool {
    return ((@as(c_int, _getCurrKeyState(virt_key)) & 0x8000) != 0); // key pressed (down) --> conv to c_int because of bug not allowing c_short to be bitwise AND'd w/ 0x8000 (https://github.com/ziglang/zig/issues/22716)
}

// checking if a toggle key is currently active
pub fn isToggled(virt_key: VK) !bool {
    if (virt_key == VK.UNDEFINED) return false;

    // checking if key can be toggled --> return error otherwise
    const toggle_key_avail: bool = switch(virt_key) {
        VK.VK_CAPITAL, VK.VK_NUMLOCK, VK.VK_SCROLL => true,
        else => false,
    };
    if (toggle_key_avail != true) return error.InvalidToggleKeyParse; // returning error to avoid confusion

    return ((_getCurrKeyState(virt_key) & 0x0001) != 0); // key toggled (i.e Caps Lock is ON)
}

// returns the current keyboard's locale identifier
pub fn getKeyboardLocaleIdAlloc(alloc: std.mem.Allocator) ![]u8 {
    // casting the buffer to a different type
    const buf: []u8 = try alloc.alloc(u8, 9); // creating an arr of size==10 (must be minimum size of 9 + 1 for \0)
    const lpstr_buf_win32: windows.LPSTR = @ptrCast(buf.ptr); // .ptr used instead of &buf to ensure that a ptr to fixed arr is gotten (not ptr to slice start)
    const res_keyboard_id_grab: windows.BOOL = GetKeyboardLayoutNameA(lpstr_buf_win32); // getting the keyboard layout ID (digits)
    if (@as(bool, res_keyboard_id_grab) != true) { // checking that GetKeyboardLayoutNameA() was successful
        return error.cannot_capture_global_keyboard;
    }
    return buf;
}

// checks if a key is a modifier key
pub fn keyIsModifier(virt_key: VK) bool {
    const modifier_res: bool = switch (virt_key) {
        VK.VK_LCONTROL, VK.VK_LSHIFT, VK.VK_LWIN, VK.VK_LMENU,
        VK.VK_RCONTROL, VK.VK_RSHIFT, VK.VK_RWIN, VK.VK_RMENU, 
        VK.VK_CONTROL, VK.VK_SHIFT, VK.VK_MENU, => true,
        else => false,
    };
    return modifier_res;
}

// simulates a person pressing a key 1x times
pub fn pressAndReleaseKey(virt_key: VK) !void {
    const virt_key_u8: u8 = try _getU8VkFromEnum(virt_key);
    try _pressAndReleaseKeyU8(virt_key_u8);
}

// pressing the keys associated w/ bytes (can print random bytes to screen) --> fast but does not check
pub fn pressKeyString(str: []const u8) !void {
    // iterating over each byte to keyboard print the char
    for (str) |char| {
        var input_arr_size_4: [4]INPUT = undefined;
        const curr_char_input_slice: []INPUT = try _charToInputSliceAlloc(input_arr_size_4[0..input_arr_size_4.len], char);
    
        // checking for the num of valid keyboard INPUTs
        var valid_input_count: c_uint = 0;
        for (curr_char_input_slice) |curr| { // iterating over each
            if (_isValidKeyboardInputType(&curr) != true) {
                break; // moving 
            }
            valid_input_count += 1;
        }
        if (valid_input_count != 2 and valid_input_count != 4) return error.Failed_To_Press_Key;

        // pressing each key --> 1ms between keypresses to ensure false keys are pressed
        var i: usize = 0;
        while (valid_input_count > i) {
            const press_key_res: c_uint = SendInput(1, &curr_char_input_slice[i], @sizeOf(INPUT)); // pressing 1x INPUT
            if (press_key_res == 0) return error.Failed_To_Send_Press_Key; // err checking
            std.time.sleep(std.time.ns_per_ms * 1); // waiting to avoid false keypresses
            i += 1; // incrementing counter to move to next INPUT{}
        }
    }
}

// pressing the keys associated w/ an ASCII string
pub fn pressKeyStringAsciiSafe(str: []const u8) !void {
    // checking that string is safe
    for (str) |char| {
        if (std.ascii.isPrint(char) != true) return error.Char_Is_Not_Printable;
    }

    // checking string for non-ASCII layout
    if (_utf8IsNotAscii(str) or _utf16IsNotAscii(str) or _utf32IsNotAscii(str)) {
        return error.non_ascii_string_parse;
    }

    // if string is ASCII-only --> print string (via keyboard)
    try pressKeyString(str);
}

// blocking all user input (system-wide) --> mouse and keyboard (used for CRITICAL functions)
pub fn blockAllUserInput() void {
    BlockInput(true);
}

// unblocking all user input (system-wide) --> mouse and keyboard (used for CRITICAL functions)
pub fn unblockAllUserInput() void {
    BlockInput(false);
}

// === PUBLIC FUNCTIONS ===
// ========================

// =========================
// === PRIVATE FUNCTIONS ===

// collecting the u8 from the specified VK value
fn _getU8VkFromEnum(virt_key_enum: VK) !u8 {
    const virt_key_c_short: c_short = @intFromEnum(virt_key_enum); // typecast to allow easy parsing of VK
    if (virt_key_c_short > 0xff) return error.virt_key_larger_than_u8;
    return @intCast(virt_key_c_short); // converts to u8 on return
}

// collecting the virtual key from a char (ASCII)
fn _getVkFromChar(ex_char: u8) c_short {
    return VkKeyScanA(ex_char);
}

// press and release key U8
fn _pressAndReleaseKeyU8(virt_key_u8: u8) !void {
    // generating the INPUT signals (structs) for the SendInput win32 func call
    const key_down_input: INPUT = _pressKeyDownOnlyU8(virt_key_u8);
    const key_up_input: INPUT = _releaseKeyUpOnlyU8(virt_key_u8);
    const input_keys: [2]INPUT = .{ key_down_input, key_up_input };
    const p_input_keys: *const INPUT = &input_keys[0]; // creating ptr to first value in array

    // checking success of sending input --> 1 == error occurred
    const res_send_input: c_uint = SendInput(2, p_input_keys, @sizeOf(INPUT));
    if (res_send_input == 0) {
        return error.failed_to_send_press_key_down_input;
    }
    std.time.sleep(std.time.ns_per_ms); // sleeping for an ms to avoid weird memory overwrites --> keyboard pressing wrong chars
}

// func for returning the INPUT struct for WM_KEYDOWN
fn _pressKeyDownOnlyU8(virt_key_u8: u8) INPUT {
    const virt_key_u16: u16 = virt_key_u8; // packing for KEYBDINPUT
    const key_down_input: INPUT = .{ // push key down
        .input_type = INPUT_KEYBOARD,
        .DUMMYUNIONNAME = .{ .ki = KEYBDINPUT {
            .wVk = virt_key_u16,
            .wScan = 0x0,
            .dwFlags = 0x0 | KEYEVENTF_EXTENDEDKEY, // EXTENDEDKEY used to allow for non-basic VKs to be used
            .time = 0x0,
            .dwExtraInfo = 0x0,
        }}
    };
    return key_down_input;
}

// func for returning the INPUT struct for WM_KEYUP 
fn _releaseKeyUpOnlyU8(virt_key_u8: u8) INPUT {
    const virt_key_u16: u16 = virt_key_u8; // packing for KEYBDINPUT
    const key_up_input: INPUT = .{ // push key down
        .input_type = INPUT_KEYBOARD,
        .DUMMYUNIONNAME = .{ .ki = KEYBDINPUT {
            .wVk = virt_key_u16,
            .wScan = 0x0,
            .dwFlags = KEYEVENTF_KEYUP | KEYEVENTF_EXTENDEDKEY, // EXTENDEDKEY used to allow for non-basic VKs to be used
            .time = 0x0,
            .dwExtraInfo = 0x0,
        }}
    };
    return key_up_input;
}

// func for returning []INPUT (slice) that contains all inputs that need to be performed for character to be pressed --> includes special chars i.e. '$'
fn _charToInputSliceAlloc(input_slice: []INPUT, ascii_char: u8) ![]INPUT {
    // checking that parsed slice is large enough
    if (input_slice.len != 4) {
        return error.Input_Slice_Len_Not_Four;
    }

    // ensuring that the provided value can be typed
    if (std.ascii.isPrint(ascii_char) != true) {
        return error.non_printable_char_parse;
    }

    // using win32 API to capture whether a modifier is required alongside VK press
    const special_vk_c_short: c_short = _getVkFromChar(ascii_char);
    const special_vk_high_bytes: u8 = @intCast((special_vk_c_short >> 8) & 0xff); // high-bytes denote the additional modifiers
    const special_requires_shift_modifier: bool = ((special_vk_high_bytes & 1) > 0); // 0x01 of high-byte denotes the SHIFT modifier requires pressing
    const special_vk_u8: u8 = @intCast(special_vk_c_short & 0xff); // removing c_short extra bytes
    
    // responding to if a modifier is required for the special key to be pressed i.e. shift
    if (special_requires_shift_modifier == true) { // modifier required
        input_slice[0] = _pressKeyDownOnlyU8(0x10); // shift key
        input_slice[1] = _pressKeyDownOnlyU8(special_vk_u8);
        input_slice[2] = _releaseKeyUpOnlyU8(0x10); // shift key
        input_slice[3] = _releaseKeyUpOnlyU8(special_vk_u8);
    } else {
        input_slice[0] = _pressKeyDownOnlyU8(special_vk_u8);
        input_slice[1] = _releaseKeyUpOnlyU8(special_vk_u8);
        input_slice[2] = .{ .input_type = 0xff, .DUMMYUNIONNAME = .{ .ki = KEYBDINPUT {.wVk = 0x0, .wScan = 0x0, .dwFlags = 0x0, .time = 0x0, .dwExtraInfo = 0x0,}}};
        input_slice[3] = .{ .input_type = 0xff, .DUMMYUNIONNAME = .{ .ki = KEYBDINPUT {.wVk = 0x0, .wScan = 0x0, .dwFlags = 0x0, .time = 0x0, .dwExtraInfo = 0x0,}}};
    }

    return input_slice;
}

// gets the state bitmap of a specified virtual key --> used to check if key as pressed down
fn _getCurrKeyState(virt_key: VK) c_short {
    const virt_key_c_short: c_short = @intFromEnum(virt_key); // converting enum val so that it is usable
    const key_state_short: c_short = GetAsyncKeyState(@as(c_int, virt_key_c_short)); // conv to c_int as per win32 API
    return key_state_short;
}

// func that checks keyboard messages in separate thread --> used for callback funcs
fn _actOnKeyboardMsgs() void {
    var msg: MSG = undefined;

    // check for O/S messages until the thread is to be closed (flag changed to true)
    while (run_threads_flag == true) {
        const msg_res: bool = (GetMessageA(&msg, null, 0x0, 0x0) != 0); // pushing recv'd message into "msg" buf
        if (msg_res == false) { // couldn't get msg --> error occurred (end thread)
            return;
        }
    
        // responding to a successful hotkey recv
        if (msg.message == WM_HOTKEY) {
            // checking if the hotkey is one of the hotkeys that have been activated here --> iterate
            const hotkey_id: windows.WPARAM = msg.wParam;
            const i_hotkey: usize = hotkey_id - 1; 
            if (hotkeys_i_opt == null) return;
            if (i_hotkey > hotkeys_i_opt.?) return;
            
            std.debug.print("hey\n", .{});
            
            // grabbing the callback struct
            const hotkey: Hotkey_Hook_Callback = hotkeys_arr[i_hotkey];
            const callback_func: *const fn (args: *anyopaque) void = @ptrCast(hotkey.callback);
            callback_func(hotkey.args);
        }
    }
}

// checking for valid INPUT types
fn _isValidKeyboardInputType(p_input: *const INPUT) bool {
    if (p_input.*.input_type != INPUT_KEYBOARD) {
        return false;
    }
    return true;
}

// checking if a string (UTF-8 encoded) is not ASCII
fn _utf8IsNotAscii(pot_ascii_str: []const u8) bool {
    for (pot_ascii_str) |char_u8| { if (char_u8 > 0x7F) return true; } // iterate over each u8
    return false;
}

// checking if a string (UTF-8 encoded) is not ASCII
fn _utf16IsNotAscii(pot_ascii_str: []const u16) bool {
    for (pot_ascii_str) |char_u16| { if (char_u16 > 0x7F) return true; } // iterate over each u8
    return false;
}

// checking if a string (UTF-16 encoded) is not ASCII
fn _utf32IsNotAscii(pot_ascii_str: []const u32) bool {
    for (pot_ascii_str) |char_u32| { if (char_u32 > 0x7F) return true; } // iterate over each u8
    return false;
}

// flipping the bool bit
fn _trueBoolCallback(p_val: *anyopaque) void {
    const p_val_bool: *bool = @ptrCast(p_val);
    p_val_bool.* = true;
}

// === PRIVATE FUNCTIONS ===
// =========================

// ====================
// === PUBLIC ENUMS ===

pub const VK = enum(c_short) { // enum for holding all of the Windows virtual keys --> associates key presses to a value
    UNDEFINED = 0x00,
    VK_LBUTTON = 0x01,
    VK_RBUTTON = 0x02,
    VK_CANCEL = 0x03,
    VK_MBUTTON = 0x04,
    VK_XBUTTON1 = 0x05,
    VK_XBUTTON2 = 0x06,
    VK_BACK = 0x08,
    VK_TAB = 0x09,
    VK_CLEAR = 0x0C,
    VK_RETURN = 0x0D,
    VK_SHIFT = 0x10,
    VK_CONTROL = 0x11,
    VK_MENU = 0x12,
    VK_PAUSE = 0x13,
    VK_CAPITAL = 0x14,
    VK_KANA = 0x15,
    // VK_HANGUL = 0x15, --> duplicate
    VK_IME_ON = 0x16,
    VK_JUNJA = 0x17,
    VK_FINAL = 0x18,
    VK_HANJA = 0x19,
    // VK_KANJI = 0x19, --> duplicate
    VK_IME_OFF = 0x1A,
    VK_ESCAPE = 0x1B,
    VK_CONVERT = 0x1C,
    VK_NONCONVERT = 0x1D,
    VK_ACCEPT = 0x1E,
    VK_MODECHANGE = 0x1F,
    VK_SPACE = 0x20,
    VK_PRIOR = 0x21,
    VK_NEXT = 0x22,
    VK_END = 0x23,
    VK_HOME = 0x24,
    VK_LEFT = 0x25,
    VK_UP = 0x26,
    VK_RIGHT = 0x27,
    VK_DOWN = 0x28,
    VK_SELECT = 0x29,
    VK_PRINT = 0x2A,
    VK_EXECUTE = 0x2B,
    VK_SNAPSHOT = 0x2C,
    VK_INSERT = 0x2D,
    VK_DELETE = 0x2E,
    VK_HELP = 0x2F,
    VK_0 = 0x30,
    VK_1 = 0x31,
    VK_2 = 0x32,
    VK_3 = 0x33,
    VK_4 = 0x34,
    VK_5 = 0x35,
    VK_6 = 0x36,
    VK_7 = 0x37,
    VK_8 = 0x38,
    VK_9 = 0x39,
    VK_A = 0x41,
    VK_B = 0x42,
    VK_C = 0x43,
    VK_D = 0x44,
    VK_E = 0x45,
    VK_F = 0x46,
    VK_G = 0x47,
    VK_H = 0x48,
    VK_I = 0x49,
    VK_J = 0x4A,
    VK_K = 0x4B,
    VK_L = 0x4C,
    VK_M = 0x4D,
    VK_N = 0x4E,
    VK_O = 0x4F,
    VK_P = 0x50,
    VK_Q = 0x51,
    VK_R = 0x52,
    VK_S = 0x53,
    VK_T = 0x54,
    VK_U = 0x55,
    VK_V = 0x56,
    VK_W = 0x57,
    VK_X = 0x58,
    VK_Y = 0x59,
    VK_Z = 0x5A,
    VK_LWIN = 0x5B,
    VK_RWIN = 0x5C,
    VK_APPS = 0x5D,
    VK_SLEEP = 0x5F,
    VK_NUMPAD0 = 0x60,
    VK_NUMPAD1 = 0x61,
    VK_NUMPAD2 = 0x62,
    VK_NUMPAD3 = 0x63,
    VK_NUMPAD4 = 0x64,
    VK_NUMPAD5 = 0x65,
    VK_NUMPAD6 = 0x66,
    VK_NUMPAD7 = 0x67,
    VK_NUMPAD8 = 0x68,
    VK_NUMPAD9 = 0x69,
    VK_MULTIPLY = 0x6A,
    VK_ADD = 0x6B,
    VK_SEPARATOR = 0x6C,
    VK_SUBTRACT = 0x6D,
    VK_DECIMAL = 0x6E,
    VK_DIVIDE = 0x6F,
    VK_F1 = 0x70,
    VK_F2 = 0x71,
    VK_F3 = 0x72,
    VK_F4 = 0x73,
    VK_F5 = 0x74,
    VK_F6 = 0x75,
    VK_F7 = 0x76,
    VK_F8 = 0x77,
    VK_F9 = 0x78,
    VK_F10 = 0x79,
    VK_F11 = 0x7A,
    VK_F12 = 0x7B,
    VK_F13 = 0x7C,
    VK_F14 = 0x7D,
    VK_F15 = 0x7E,
    VK_F16 = 0x7F,
    VK_F17 = 0x80,
    VK_F18 = 0x81,
    VK_F19 = 0x82,
    VK_F20 = 0x83,
    VK_F21 = 0x84,
    VK_F22 = 0x85,
    VK_F23 = 0x86,
    VK_F24 = 0x87,
    VK_NUMLOCK = 0x90,
    VK_SCROLL = 0x91,
    VK_LSHIFT = 0xA0,
    VK_RSHIFT = 0xA1,
    VK_LCONTROL = 0xA2,
    VK_RCONTROL = 0xA3,
    VK_LMENU = 0xA4,
    VK_RMENU = 0xA5,
    VK_BROWSER_BACK = 0xA6,
    VK_BROWSER_FORWARD = 0xA7,
    VK_BROWSER_REFRESH = 0xA8,
    VK_BROWSER_STOP = 0xA9,
    VK_BROWSER_SEARCH = 0xAA,
    VK_BROWSER_FAVORITES = 0xAB,
    VK_BROWSER_HOME = 0xAC,
    VK_VOLUME_MUTE = 0xAD,
    VK_VOLUME_DOWN = 0xAE,
    VK_VOLUME_UP = 0xAF,
    VK_MEDIA_NEXT_TRACK = 0xB0,
    VK_MEDIA_PREV_TRACK = 0xB1,
    VK_MEDIA_STOP = 0xB2,
    VK_MEDIA_PLAY_PAUSE = 0xB3,
    VK_LAUNCH_MAIL = 0xB4,
    VK_LAUNCH_MEDIA_SELECT = 0xB5,
    VK_LAUNCH_APP1 = 0xB6,
    VK_LAUNCH_APP2 = 0xB7,
    VK_OEM_1 = 0xBA,
    VK_OEM_PLUS = 0xBB,
    VK_OEM_COMMA = 0xBC,
    VK_OEM_MINUS = 0xBD,
    VK_OEM_PERIOD = 0xBE,
    VK_OEM_2 = 0xBF,
    VK_OEM_3 = 0xC0,
    VK_OEM_4 = 0xDB,
    VK_OEM_5 = 0xDC,
    VK_OEM_6 = 0xDD,
    VK_OEM_7 = 0xDE,
    VK_OEM_8 = 0xDF,
    VK_OEM_102 = 0xE2,
    VK_PROCESSKEY = 0xE5,
    VK_PACKET = 0xE7,
    VK_ATTN = 0xF,
    VK_CRSEL = 0xF7,
    VK_EXSEL = 0xF8,
    VK_EREOF = 0xF9,
    VK_PLAY = 0xFA,
    VK_ZOOM = 0xFB,
    VK_NONAME = 0xFC,
    VK_PA1 = 0xFD,
    VK_OEM_CLEAR = 0xFE,
};

// === PUBLIC ENUMS ===
// ====================