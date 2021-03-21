import teensy, keyboard

const
  rows = [D0, D1, D2, D3, C6, C7, D5]
  columns = [B0, B1, B2, B3, B7]
  rowKeys = [KeyA, KeyS, KeyD, KeyF, KeyG, KeyH, KeyJ]
  colKeys = [Key0, Key1, Key2, Key3, Key4]

proc main() {.exportc.} =
  cpuPrescale(0)

  usbInit()
  while usbConfigured() == 0: discard

  delayMs(1000)

  Led.output()

  columns.configure(input, pullup)
  rows.configure(input, pullup)

  while true:
    for col in withPinAs(columns, output, low):
      for row in withPinAs(rows, pullup):
        delayMs(2)
        if row.readPin() == 0:
          discard usbKeyboardPress(colKeys[col], 0)
          discard usbKeyboardPress(rowKeys[row], 0)
          discard usbKeyboardPress(KeySpace, 0)
