import teensy, pgmspace, mappings/dvorak, layouts, usbKeyboard

const
  columns = [D5, C7, C6, D3, D2, D1, D0]
  rows = [B7, B3, B2, B1, B0]

template myKey(): untyped =
  when defined(something):
    KEY_C
  else:
    KEY_P

const MyKey = KEY_OSLASH

proc runCopy() =
  discard usbKeyboardPress(KEY_C, MOD_CTRL)

proc typeAs(times: int) =
  for i in 0..<times:
    discard usbKeyboardPress(KEY_A, MOD_NONE)
  discard usbKeyboardPress(KEY_SPACE, MOD_NONE)

var layout: uint8 = 0

proc switchLayout(l: uint8) =
  layout = l

proc setModifier(m: Modifiers) {.noinline.} =
  keyboardModifierKeys = keyboardModifierKeys or m

createLayout(layout1):
  Æ         B C D       E               F         Backspace
  Ø         I J MyKey   L               M         MOD_ALT.setModifier()
  Å         P Q myKey() S               T         MOD_CTRL.setModifier()
  V         W X Y       Z               1         MOD_SHIFT.setModifier()
  runCopy() 4 5 6       switchLayout(1) typeAs(3) typeAs(5)

createLayout(layout2):
  Q         P E T       E               R         Backspace
  H         I J MyKey   L               M         N
  O         P Q myKey() S               T         U
  V         W X Y       Z               1         2
  runCopy() 4 5 6       switchLayout(0) typeAs(1) typeAs(7)

proc main() {.exportc.} =
  cpuPrescale(0)

  usbInit()
  while usbConfigured() == 0: discard

  delayMs(1000)

  rows.configure(input, pullup)
  columns.configure(input, pullup)

  while true:
    var i = 0
    reset keyboardKeys
    reset keyboardModifierKeys
    for row in withPinAs(rows, output, low):
      for col in withPinAs(columns, pullup):
        delayLoop(1'u8)
        if col.readPin() == 0:
          if i < 6:
            let key = case range[0..1](layout):
            of 0: layout1[row*columns.len + col]
            of 1: layout2[row*columns.len + col]
            if key.uint8 > 231:
              layoutCallback(key)
            else:
              keyboardKeys[i] = key
            inc i
    discard usbKeyboardSend()
