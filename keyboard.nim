{.compile: "usb_keyboard.c".}
{.push nodecl, header: "\"usb_keyboard.h\"".}
proc `or`*(x, y: Modifiers): Modifiers = Modifiers(x.uint8 or y.uint8)

proc usbInit*() {.importc: "usb_init".}
proc usbConfigured*(): uint8 {.importc: "usb_configured".}
proc usbKeyboardPress*(key: Key, modifier: Modifiers): int8 {.importc: "usb_keyboard_press".}
proc usbKeyboardSend*(): int8 {.importc: "usb_keyboard_send".}
var
  keyboardModifierKeys* {.importc: "keyboard_modifier_keys"}: Modifiers
  keyboardKeys* {.importc: "keyboard_keys".}: array[6, Key]
{.pop.}
