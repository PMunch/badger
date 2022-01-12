import macros, tables

{.push nodecl, header: "<avr/io.h>".}
var
  clkpr* {.importc: "CLKPR".}: uint8
  portD* {.importc: "PORTD".}: uint8
  ddrD* {.importc: "DDRD".}: uint8
  pinD* {.importc: "PIND".}: uint8
  portB* {.importc: "PORTB".}: uint8
  ddrB* {.importc: "DDRB".}: uint8
  pinB* {.importc: "PINB".}: uint8
  portF* {.importc: "PORTF".}: uint8
  ddrF* {.importc: "DDRF".}: uint8
  pinF* {.importc: "PINF".}: uint8
  portC* {.importc: "PORTC".}: uint8
  ddrC* {.importc: "DDRC".}: uint8
  pinC* {.importc: "PINC".}: uint8
  portE* {.importc: "PORTE".}: uint8
  ddrE* {.importc: "DDRE".}: uint8
  pinE* {.importc: "PINE".}: uint8

  twbr* {.importc: "TWBR".}: uint8
  twcr* {.importc: "TWCR".}: uint8
  twsr* {.importc: "TWSR".}: uint8
  twdr* {.importc: "TWDR".}: uint8

let
  twint* {.importc: "TWINT".}: uint8
  twea* {.importc: "TWEA".}: uint8
  twsta* {.importc: "TWSTA".}: uint8
  twsto* {.importc: "TWSTO".}: uint8
  twwc* {.importc: "TWWC".}: uint8
  twen* {.importc: "TWEN".}: uint8
  twie* {.importc: "TWIE".}: uint8

template cpuPrescale*(n: static[uint8]): untyped =
  clkpr = 0x80
  clkpr = n
{.pop.}

type
  Teensy = object
  Port = object
    device: Teensy
    portChar: char
  Pin = object
    port: Port
    num: int

const this = Teensy()

proc pin(port: char, num: int): Pin {.compileTime.} =
  Pin(port: Port(portChar: port), num: num)
  #Pin(port: port, num: num)

const
  D* = Port(portChar: 'D')
  B0* = pin('B', 0)
  B1* = pin('B', 1)
  B2* = pin('B', 2)
  B3* = pin('B', 3)
  B4* = pin('B', 4)
  B5* = pin('B', 5)
  B6* = pin('B', 6)
  B7* = pin('B', 7)
  D0* = pin('D', 0)
  D1* = pin('D', 1)
  D2* = pin('D', 2)
  D3* = pin('D', 3)
  D4* = pin('D', 4)
  D5* = pin('D', 5)
  D6* = pin('D', 6)
  D7* = pin('D', 7)
  F0* = pin('F', 0)
  F1* = pin('F', 1)
  F4* = pin('F', 4)
  F5* = pin('F', 5)
  F6* = pin('F', 6)
  F7* = pin('F', 7)
  C6* = pin('C', 6)
  C7* = pin('C', 7)
  E6* = pin('E', 6)
  LED* = D6

macro eachIt*(pins: static[openArray[Pin]], body: untyped): untyped =
  result = newStmtList()
  let it = newIdentNode("it")
  for pin in pins:
    result.add quote do:
      block:
        const `it` = `pin`
        `body`

template expandPin(register: string): untyped {.dirty.} =
  let
    port = newIdentNode(register & $pin.port.portChar)
    num = newLit(pin.num)

template expandPort(register: string): untyped {.dirty.} =
  let portReg = newIdentNode(register & $port.portChar)

# TODO: Rewrite to work on device object

macro direction*(port: static[Port]): untyped =
  expandPort("ddr")
  quote do:
    `portReg`

macro direction*(pin: static[Pin]): untyped =
  #expandPin("ddr")
  let
    port = pin.port
    mask = newLit(1'u8 shl pin.num)
  quote do:
    direction(`port`) and `mask`

macro state*(port: static[Port]): untyped =
  expandPort("port")
  quote do:
    `portReg`

macro state*(pin: static[Pin]): untyped =
  #expandPin("ddr")
  let
    port = pin.port
    mask = newLit(1'u8 shl pin.num)
  quote do:
    state(`port`) and `mask`

macro output*(port: static[Port], mask = 0xff'u8): untyped =
  expandPort("ddr")
  quote do:
    `portReg` = `mask`

macro output*(pin: static[Pin]): untyped =
  let
    port = pin.port
    mask = newLit(1'u8 shl pin.num)
  quote do:
    output(`port`, direction(`port`) or `mask`)

macro high*(port: static[Port], mask = 0xff'u8): untyped =
  expandPort("port")
  quote do:
    `portReg` = `mask`

macro high*(pin: static[Pin]): untyped =
  let
    port = pin.port
    mask = newLit(1'u8 shl pin.num)
  quote do:
    high(`port`, state(`port`) or `mask`)

macro low*(port: static[Port], mask = 0xff'u8): untyped =
  expandPort("port")
  quote do:
    `portReg` = `mask`

macro low*(pin: static[Pin]): untyped =
  let
    port = pin.port
    mask = newLit(1'u8 shl pin.num)
  quote do:
    low(`port`, state(`port`) and not `mask`)

macro input*(port: static[Port], mask = 0xff'u8): untyped =
  expandPort("ddr")
  quote do:
    `portReg` = `mask`

macro input*(pin: static[Pin]): untyped =
  let
    port = pin.port
    mask = newLit(1'u8 shl pin.num)
  quote do:
    input(`port`, direction(`port`) and not `mask`)

template normal*(port: static[Port], mask = 0xff'u8): untyped =
  low(port, mask)

template normal*(pin: static[Pin]): untyped =
  low(pin)

template pullup*(port: static[Port], mask = 0xff'u8): untyped =
  high(port, mask)

template pullup*(pin: static[Pin]): untyped =
  high(pin)

macro read*(port: static[Port]): untyped =
  expandPort("pin")
  quote do:
    `portReg`

macro read*(pin: static[Pin]): untyped =
  let
    port = pin.port
    mask = newLit(1'u8 shl pin.num)
  quote do:
    read(`port`) and `mask`

# TODO: Rewrite to use the Port versions above
macro configure*(pins: static[openarray[Pin]], states: varargs[untyped]): untyped =
  result = newStmtList()
  var ports: Table[char, seq[int]]
  for pin in pins:
    ports.mgetOrPut(pin.port.portChar, @[]).add pin.num
  for state in states:
    expectKind state, nnkIdent
    for portName, pins in ports.pairs:
      var valueMask = newLit(0)
      for pin in pins:
        valueMask = quote do:
          `valueMask` or (1'u8 shl `pin`)
      case state.strVal:
      of "input":
        let port = newIdentNode("ddr" & $portName)
        result.add quote do:
          `port` = `port` and not `valueMask`
      of "output":
        let port = newIdentNode("ddr" & $portName)
        result.add quote do:
          `port` = `port` or `valueMask`
      of "pullup":
        let port = newIdentNode("port" & $portName)
        result.add quote do:
          `port` = `port` or `valueMask`
      of "normal":
        let port = newIdentNode("port" & $portName)
        result.add quote do:
          `port` = `port` and not `valueMask`
      of "high":
        let port = newIdentNode("port" & $portName)
        result.add quote do:
          `port` = `port` or `valueMask`
      of "low":
        let port = newIdentNode("port" & $portName)
        result.add quote do:
          `port` = `port` and not `valueMask`
      else: doAssert state.strVal in ["input", "output", "pullup", "normal", "high", "low"]
  #echo result.repr

macro generateCaseStmt(pinsCount: static[int], pinsname: untyped, iterVar: untyped, states: varargs[untyped]): untyped =
  result = quote do:
    case range[0..`pinsname`.high](`iterVar`):
    else: discard
  result.del 1
  for i in 0..pinsCount:
    var body = newStmtList()
    for state in states:
      body.add quote do:
        `state`(`pinsname`[`i`])
    result.add nnkOfBranch.newTree(newLit(i), body)
  #echo result.repr

macro withPinAs*(loop: ForLoopStmt): untyped =
  expectKind loop, nnkForStmt
  let
    iterVar = loop[0]
    pins = loop[1][1]
    states = loop[1][2..^1]
    body = loop[2]
    iterVarType = genSym(nskType)
  var
    generateSym = bindSym("generateCaseStmt")
    generateInStmt = nnkCall.newTree(generateSym, newCall("high", pins), pins, iterVar)
    generateOutStmt = nnkCall.newTree(generateSym, newCall("high", pins), pins, iterVar)
    generateReadStmt = nnkCall.newTree(generateSym, newCall("high", pins), pins, iterVar, newIdentNode("read"))
  for state in states:
    generateInStmt.add state
    generateOutStmt.add:
      case state.strVal:
      of "input": newIdentNode("output")
      of "output": newIdentNode("input")
      of "pullup": newIdentNode("normal")
      of "normal": newIdentNode("pullup")
      of "high": newIdentNode("low")
      of "low": newIdentNode("high")
      else: newIdentNode("error")
  result = quote do:
    type `iterVarType` = int
    for i in 0..`pins`.high:
      let `iterVar` = `iterVarType`(i)
      template readPin(_: `iterVarType`): untyped {.used.} =
        `generateReadStmt`
      `generateInStmt`
      `body`
      `generateOutStmt`
  #echo result.repr

proc delayMs*(ms: cdouble) {.importc: "_delay_ms", header: "<avr/delay.h>".}
proc delayUs*(ms: cdouble) {.importc: "_delay_us", header: "<avr/delay.h>".}
proc delayLoop*(its: uint8) {.importc: "_delay_loop_1", header: "<util/delay_basic.h>".}
proc delayLoop*(its: uint16) {.importc: "_delay_loop_2", header: "<util/delay_basic.h>".}
proc millis*(): culong {.importc, nodecl.}

template expandFlags(flags: untyped): untyped =
  var flagCollection {.inject.} = newLit(0'u8)
  for flag in flags:
    flagCollection = nnkInfix.newTree(newIdentNode("or"),
      flagCollection, nnkInfix.newTree(newIdentNode("shl"), newLit(1'u8), flag))
  #echo flagCollection.repr

macro check*(x: uint8, flags: varargs[untyped]): untyped =
  expandFlags(flags)
  quote do:
    (`x` and (`flagCollection`)) != 0

macro set*(x: uint8, flags: varargs[untyped]): untyped =
  expandFlags(flags)
  quote do:
    `x` = `flagCollection`

macro unset*(x: uint8, flags: varargs[untyped]): untyped =
  expandFlags(flags)
  quote do:
    `x` = not `flagCollection`

