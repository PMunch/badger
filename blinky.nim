import macros

{.emit: "#define CPU_PRESCALE(n) (CLKPR = 0x80, CLKPR = (n))".}
{.push nodecl, header: "<avr/io.h>".}
var
  portD {.importc: "PORTD".}: uint8
  ddrD {.importc: "DDRD".}: uint8
  pinD {.importc: "PIND".}: uint8
  portB {.importc: "PORTB".}: uint8
  ddrB {.importc: "DDRB".}: uint8
  pinB {.importc: "PINB".}: uint8
  portF {.importc: "PORTF".}: uint8
  ddrF {.importc: "DDRF".}: uint8
  pinF {.importc: "PINF".}: uint8
  portC {.importc: "PORTC".}: uint8
  ddrC {.importc: "DDRC".}: uint8
  pinC {.importc: "PINC".}: uint8
  portE {.importc: "PORTE".}: uint8
  ddrE {.importc: "DDRE".}: uint8
  pinE {.importc: "PINE".}: uint8
{.pop.}

type Pin = object
  port: char
  num: int

proc pin(port: char, num: int): Pin {.compileTime.} =
  Pin(port: port, num: num)

const
  B0 = pin('B', 0)
  B1 = pin('B', 1)
  B2 = pin('B', 2)
  B3 = pin('B', 3)
  B4 = pin('B', 4)
  B5 = pin('B', 5)
  B6 = pin('B', 6)
  B7 = pin('B', 7)
  D0 = pin('D', 0)
  D1 = pin('D', 1)
  D2 = pin('D', 2)
  D3 = pin('D', 3)
  D4 = pin('D', 4)
  D5 = pin('D', 5)
  D6 = pin('D', 6)
  D7 = pin('D', 7)
  F0 = pin('F', 0)
  F1 = pin('F', 1)
  F4 = pin('F', 4)
  F5 = pin('F', 5)
  F6 = pin('F', 6)
  F7 = pin('F', 7)
  C6 = pin('C', 6)
  C7 = pin('C', 7)
  E6 = pin('E', 6)
  LED = D6

template expandPin(register: string): untyped {.dirty.} =
  var
    port = newIdentNode(register & $pin.port)
    num = newLit(pin.num)

macro output(pin: static[Pin]): untyped =
  expandPin("ddr")
  quote do:
    `port` = `port` or (1'u8 shl `num`)

macro high(pin: static[Pin]): untyped =
  expandPin("port")
  quote do:
    `port` = `port` or (1'u8 shl `num`)

macro low(pin: static[Pin]): untyped =
  expandPin("port")
  quote do:
    `port` = `port` and not (1'u8 shl `num`)

macro input(pin: static[Pin]): untyped =
  expandPin("ddr")
  quote do:
    `port` = `port` and not (1'u8 shl `num`)

macro normal(pin: static[Pin]): untyped =
  expandPin("port")
  quote do:
    `port` = `port` and not (1'u8 shl `num`)

macro pullup(pin: static[Pin]): untyped =
  expandPin("port")
  quote do:
    `port` = `port` or (1'u8 shl `num`)

macro read(pin: static[Pin]): untyped =
  expandPin("pin")
  quote do:
    `port` and (1'u8 shl `num`)

proc delayMs(ms: cdouble) {.importc: "_delay_ms", header: "<avr/delay.h>".}

proc main() {.exportc.} =
  {.emit: "CPU_PRESCALE(0);".}
  Led.output()
  B6.input()
  B6.pullup()

  while true:
    if B6.read() != 0:
      Led.low()
    else:
      Led.high()
    delayMs(100)
