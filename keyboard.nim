{.compile: "usb_keyboard.c".}
{.push nodecl, header: "\"usb_keyboard.h\"".}

type
  Key* = enum
    KEY_A = 4, KEY_B = 5, KEY_C = 6, KEY_D = 7, KEY_E = 8, KEY_F = 9, KEY_G = 10
    KEY_H = 11, KEY_I = 12, KEY_J = 13, KEY_K = 14, KEY_L = 15, KEY_M = 16,
    KEY_N = 17, KEY_O = 18, KEY_P = 19, KEY_Q = 20, KEY_R = 21, KEY_S = 22,
    KEY_T = 23, KEY_U = 24, KEY_V = 25, KEY_W = 26, KEY_X = 27, KEY_Y = 28,
    KEY_Z = 29, KEY_1 = 30, KEY_2 = 31, KEY_3 = 32, KEY_4 = 33, KEY_5 = 34,
    KEY_6 = 35, KEY_7 = 36, KEY_8 = 37, KEY_9 = 38, KEY_0 = 39, KEY_ENTER = 40,
    KEY_ESC = 41, KEY_BACKSPACE = 42, KEY_TAB = 43, KEY_SPACE = 44,
    KEY_MINUS = 45, KEY_EQUAL = 46, KEY_LEFT_BRACE = 47, KEY_RIGHT_BRACE = 48,
    KEY_BACKSLASH = 49, KEY_NUMBER = 50, KEY_SEMICOLON = 51, KEY_QUOTE = 52,
    KEY_TILDE = 53, KEY_COMMA = 54, KEY_PERIOD = 55, KEY_SLASH = 56,
    KEY_CAPS_LOCK = 57, KEY_F1 = 58, KEY_F2 = 59, KEY_F3 = 60, KEY_F4 = 61,
    KEY_F5 = 62, KEY_F6 = 63, KEY_F7 = 64, KEY_F8 = 65, KEY_F9 = 66,
    KEY_F10 = 67, KEY_F11 = 68, KEY_F12 = 69, KEY_PRINTSCREEN = 70,
    KEY_SCROLL_LOCK = 71, KEY_PAUSE = 72, KEY_INSERT = 73, KEY_HOME = 74,
    KEY_PAGE_UP = 75, KEY_DELETE = 76, KEY_END = 77, KEY_PAGE_DOWN = 78,
    KEY_RIGHT = 79, KEY_LEFT = 80, KEY_DOWN = 81, KEY_UP = 82,
    KEY_NUM_LOCK = 83, KEYPAD_SLASH = 84, KEYPAD_ASTERIX = 85,
    KEYPAD_MINUS = 86, KEYPAD_PLUS = 87, KEYPAD_ENTER = 88, KEYPAD_1 = 89,
    KEYPAD_2 = 90, KEYPAD_3 = 91, KEYPAD_4 = 92, KEYPAD_5 = 93, KEYPAD_6 = 94,
    KEYPAD_7 = 95, KEYPAD_8 = 96, KEYPAD_9 = 97, KEYPAD_0 = 98,
    KEYPAD_PERIOD = 99
  Modifiers* = enum
    KEY_NONE = 0x0,
    KEY_CTRL = 0x01, KEY_SHIFT = 0x02, KEY_ALT = 0x04, KEY_GUI = 0x08,
    KEY_RIGHT_CTRL = 0x10, KEY_RIGHT_SHIFT = 0x20, KEY_RIGHT_ALT = 0x40,
    KEY_RIGHT_GUI = 0x80

template KEY_LEFT_CTRL*(): untyped = KEY_CTRL
template KEY_LEFT_SHIFT*(): untyped = KEY_SHIFT
template KEY_LEFT_ALT*(): untyped = KEY_ALT
template KEY_LEFT_GUI*(): untyped = KEY_GUP

proc `or`*(x, y: Modifiers): Modifiers = Modifiers(x.uint8 or y.uint8)

proc usbInit*() {.importc: "usb_init".}
proc usbConfigured*(): uint8 {.importc: "usb_configured".}
proc usbKeyboardPress*(key: Key, modifier: Modifiers): int8 {.importc: "usb_keyboard_press".}
proc usbKeyboardSend*(): int8 {.importc: "usb_keyboard_send".}
var
  keyboardModifierKeys* {.importc: "keyboard_modifier_keys"}: Modifiers
  keyboardKeys* {.importc: "keyboard_keys".}: array[6, Key]
{.pop.}
