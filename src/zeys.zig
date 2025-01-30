// std Zig imports
const std = @import("std");
const c = std.c;
const windows = std.os.windows;


// Windows API functionality
const KEYEVENTF_EXTENDEDKEY = 0x0001; // for including non-alphanumeric keys
const KEYEVENTF_KEYUP = 0x0002; // for releasing a key
const INPUT_KEYBOARD = 0x01; // setting input send from keyboard
const WM_KEYUP = 0x0101; // used for releasing key messages
const WM_KEYDOWN = 0x0100; // used for pressing key messages
extern "user32" fn GetAsyncKeyState(vKey: c_int) c_short;
extern "user32" fn BlockInput(block_flag: bool) bool;
extern "user32" fn GetForegroundWindow() windows.HWND;
extern "user32" fn VkKeyScanA(ch: u8) c_short;
extern "user32" fn SendInput(cInputs: c_uint, pInputs: *const INPUT, cbSize: c_int) c_uint;
extern "user32" fn SendMessage(hWnd: windows.HWND, Msg: c_uint, wParam: windows.WPARAM, lParam: windows.LPARAM) windows.LRESULT;
extern "user32" fn GetKeyboardLayoutName(pwszKLID: windows.LPSTR) bool;


// === extern struct definitions ===


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


// === PUBLIC FUNCTIONS ===


// simulates a while (true) {} without high CPU usage 
pub fn zeysInfWait() void {
    while (true) {
        std.time.sleep(10e6);
    }
}

// checking if a key is currently activated
pub fn isPressed(virt_key: VK) bool {
    return ((_getCurrKeyState(virt_key) & 0x8000) != 0); // key pressed (down)
}

// checking if a toggle key is currently active
pub fn isToggled(virt_key: VK) !bool {
    // checking if key can be toggled --> return error otherwise
    const toggle_key_avail: bool = switch(virt_key) {
        VK.VK_CAPITAL, VK.VK_NUMLOCK, VK.VK_SCROLL => true,
        else => false,
    };
    if (toggle_key_avail != true) return error.InvalidToggleKeyParse; // returning error to avoid confusion

    return ((_getCurrKeyState(virt_key) & 0x0001) != 0); // key toggled (i.e Caps Lock is ON)
}







TODO

// returns the current keyboard's locale identifier
pub fn getKeyboardLocaleIdentifier() ![*:0]u8 {
    const null_term_buf: [10:0]u8 = undefined;
    const lpstr_buf: windows.LPSTR = null_term_buf[0];
    const res_keyboard_id_grab: bool = GetKeyboardLayoutName(lpstr_buf);
    if (res_keyboard_id_grab != true) {
        return error.cannot_capture_global_keyboard;
    }
    return lpstr_buf;
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
    // iterating over each byte to check string print validity
    for (str) |char| {
        // checking that the string consists only of alphanumeric chars
        if (std.ascii.isAlphanumeric(char) != true) {
            return error.char_is_not_alphanumeric;
        }
    }  

    // iterating over each byte to keyboard print the string
    for (str) |char| {
        const vk_from_char: c_short = _getVkFromChar(char); // converting character to virtual key (no need for size check before typecast as this has been done above)
        const vk_u8: u8 = @intCast(vk_from_char & 0xFF);
        try _pressAndReleaseKeyU8(vk_u8); // pressing the current chars key
    }
}

// pressing the keys associated w/ an ASCII string
pub fn pressKeyStringAsciiSafe(str: []const u8) !void {
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

// gets the state bitmap of a specified virtual key
fn _getCurrKeyState(virt_key: VK) i32 {
    const virt_key_u8: c_short = @intFromEnum(virt_key); // converting enum val so that it is usable
    const virt_key_int: c_int = virt_key_u8; // converting to c_int for ABI compatibility

    // getting the state of a Windows key
    const key_state_short: c_short = GetAsyncKeyState(virt_key_int);
    const key_state_i32: i32 = key_state_short; // converting back to Zig ABI (unsure if this is required)

    return key_state_i32;
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








TODO

// func for returning []INPUT (slice) that contains all inputs that need to be performed for character to be pressed --> includes special chars i.e. '$'
fn _charToInputSliceAlloc(alloc: std.mem.Allocator, ascii_char: u8) ![]INPUT {
    // ensuring that the provided value can be typed
    if (std.ascii.isPrint(ascii_char) != true) {
        return error.non_printable_char_parse;
    }

    var input_arr_list = std.ArrayList(INPUT).init(alloc); // store all INPUTs for a character (modifier + key [KEYUP + KEYDOWN])
    defer alloc.free(input_arr_list); // not required due to .toOwnedSlice() return but have left here as good practice

    // single key vs multi-key press required
    if (std.ascii.isAlphanumeric(ascii_char)) {
        input_arr_list.append(_pressKeyDownOnlyU8(ascii_char));
        input_arr_list.append(_releaseKeyUpOnlyU8(ascii_char));
    } // else if () {

    // } else {
    //     return error.unknown_printable_character;
    // }

    return input_arr_list.toOwnedSlice();
}


// === PUBLIC ENUMS ===


pub const VK = enum(c_short) { // enum for holding all of the Windows virtual keys --> associates key presses to a value
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
