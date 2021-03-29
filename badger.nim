import teensy, keyboard, pgmspace

const
  rows = [D0, D1, D2, D3, C6, C7, D5]
  columns = [B0, B1, B2, B3, B7]

progmem:
  rowKeys = [KeyA, KeyS, KeyD, KeyF, KeyG, KeyH, KeyJ]
  colKeys = [Key0, Key1, Key2, Key3, Key4]
  layout = [KEY_A, KEY_B, KEY_C, KEY_D, KEY_E, KEY_F, KEY_G,
    KEY_H, KEY_I, KEY_J, KEY_K, KEY_L, KEY_M, KEY_N, KEY_O, KEY_P, KEY_Q,
    KEY_R, KEY_S, KEY_T, KEY_U, KEY_V, KEY_W, KEY_X, KEY_Y, KEY_Z, KEY_1,
    KEY_2, KEY_BACKSPACE, KEY_4, KEY_5, KEY_6, KEY_7, KEY_8, KEY_9]

proc main() {.exportc.} =
  cpuPrescale(0)

  usbInit()
  while usbConfigured() == 0: discard

  delayMs(1000)

  Led.output()

  columns.configure(input, pullup)
  rows.configure(input, pullup)

  while true:
    var i = 0
    reset keyboardKeys
    for col in withPinAs(columns, output, low):
      for row in withPinAs(rows, pullup):
        delayMs(2)
        if row.readPin() == 0:
          if i < 6:
            keyboardKeys[i] = layout[col*rows.len + row]
            inc i
    discard usbKeyboardSend()
