import teensy except F1, F4, F5, F6, F7, D
import pgmspace, mappings/dvorak, layouts, keyboard, mcp23017

const
  portexLeft  = 0b0100_0000'u8
  portexRight = 0b0100_0010'u8
portexLeft.defineMcp23017(I2CBus, L)
portexRight.defineMcp23017(I2CBus, R)

const
  columnsL = [LA0, LA1, LA2, LA3, LA4, LA5, LA6]
  rowsL = [LB7, LB6, LB5, LB4, LB3]
  columnsR = [RA0, RA1, RA2, RA3, RA4, RA5, RA6]
  rowsR = [RB3, RB4, RB5, RB6, RB7]

template myKey(): untyped =
  when defined(something):
    KEY_C
  else:
    KEY_P

const MyKey = KEY_OSLASH

var layer: range[0'u8..1'u8] = 0

proc switch(l: uint8) =
  layer = l
  delayMs(150)

proc m(m: Modifiers) {.noinline.} =
  keyboardModifierKeys = keyboardModifierKeys or m

template AltGr =
  ModRightAlt.m

createLayout(left1):
  Home       Pipe     1        2         3         4        5
  PageUp     Tab      Å        Comma     Period    P        Y
  PageDown   CapsLock A        O         E         U        I
  End        Ø        Æ        Q         J         K        X
  ModShift.m Delete   ModAlt.m switch(1) ModCtrl.m ModGui.m Space

createLayout(left2):
  Home       Pipe     F1       F2        F3        F4       F5
  PageUp     Tab      Å        Comma     Period    P        Y
  PageDown   CapsLock A        O         E         U        I
  End        Ø        Æ        Q         J         K        X
  ModShift.m Delete   ModAlt.m switch(0) ModCtrl.m ModGui.m Space

createLayout(right1):
  6     7          8         9       0        Plus       Backspace
  F     G          C         R       L        Apostrophe AngleBracket
  D     H          T         N       S        Minus      Enter
  B     M          W         V       Z        Umlaut     ModShift.m
  Space ModShift.m switch(1) AltGr() ModGui.m Backslash  ModCtrl.m

createLayout(right2):
  F6    F7         F8        F9       F10      F11        F12
  F     G          Up        R        L        VolumeUp   Mute
  D     Left       Down      Right    S        VolumeDown Enter
  B     M          W         V        Z        Umlaut     ModShift.m
  Space ModShift.m switch(0) AltGr()  ModGui.m Backslash  ModCtrl.m

proc handleForLayout(i: var int, pos: int, left: bool) =
  let key = case left:
  of true:
    case layer:
    of 0: left1[pos]
    of 1: left2[pos]
  of false:
    case layer:
    of 0: right1[pos]
    of 1: right2[pos]
  if not key.callback:
    keyboardKeys[i] = key
    inc i

proc main(): cint {.exportc.} =
  cpuPrescale(0)

  I2Cbus.init()

  usbInit()
  while usbConfigured() == 0: discard

  #delayMs(1000)

  I2Cbus.initMCP23017(portexRight)
  rowsR.configure(input, pullup)
  columnsR.configure(input, pullup)

  I2Cbus.initMCP23017(portexLeft)
  rowsL.configure(input, pullup)
  columnsL.configure(input, pullup)

  while true:
    var i = 0
    reset keyboardKeys
    reset keyboardModifierKeys

    for row in rowsL.low..rowsL.high:
      LPortB.output(1'u8 shl (7 - row))
      LPortB.low(1'u8 shl (7 - row))
      delayLoop(1'u8)
      let data = LPortA.read()
      for col in columnsL.low..columnsL.high:
        if data[col] == 0:
          if i < 6:
            handleForLayout(i, row*columnsL.len + col, true)
    for row in rowsR.low..rowsR.high:
      RPortB.output(1'u8 shl (3 + row))
      RPortB.low(1'u8 shl (3 + row))
      delayLoop(1'u8)
      let data = RPortA.read()
      for col in columnsR.low..columnsR.high:
        if data[col] == 0:
          if i < 6:
            handleForLayout(i, row*columnsR.len + col, false)

    discard usbKeyboardSend()
