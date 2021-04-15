import macros
import teensy, i2c
export i2c

type
  ExternalPin* = object
    bus: I2c
    address: uint8
    port: char
    num: int

proc pin(address: uint8, bus: I2c, port: char, num: int): ExternalPin {.compileTime.} =
  ExternalPin(address: address, port: port, num: num)

template defineMCP23017*(address: uint8, bus: I2c, prefix: untyped): untyped =
  const
    `prefix A0`* {.inject.} = pin(address, bus, 'A', 0)
    `prefix A1`* {.inject.} = pin(address, bus, 'A', 1)
    `prefix A2`* {.inject.} = pin(address, bus, 'A', 2)
    `prefix A3`* {.inject.} = pin(address, bus, 'A', 3)
    `prefix A4`* {.inject.} = pin(address, bus, 'A', 4)
    `prefix A5`* {.inject.} = pin(address, bus, 'A', 5)
    `prefix A6`* {.inject.} = pin(address, bus, 'A', 6)
    `prefix A7`* {.inject.} = pin(address, bus, 'A', 7)
    `prefix B0`* {.inject.} = pin(address, bus, 'B', 0)
    `prefix b1`* {.inject.} = pin(address, bus, 'B', 1)
    `prefix B2`* {.inject.} = pin(address, bus, 'B', 2)
    `prefix B3`* {.inject.} = pin(address, bus, 'B', 3)
    `prefix B4`* {.inject.} = pin(address, bus, 'B', 4)
    `prefix B5`* {.inject.} = pin(address, bus, 'B', 5)
    `prefix B6`* {.inject.} = pin(address, bus, 'B', 6)
    `prefix B7`* {.inject.} = pin(address, bus, 'B', 7)

template expandRegister(registerAddress: uint8): untyped {.dirty.} =
  let
    register = newLit(registerAddress or (if pin.port == 'A': 0'u8 else: 0x10'u8))
    address = newLit(pin.address)
    num = newLit(pin.num)
    bus = newLit(pin.bus)

macro output*(pin: static[ExternalPin]): untyped =
  expandRegister(0x00)
  quote do:
    let port = `bus`.readRegister(`address`, `register`)
    `bus`.writeRegister(`address`, `register`, port and (not (1'u8 shl `num`)))

macro input*(pin: static[ExternalPin]): untyped =
  expandRegister(0x00)
  quote do:
    let port = `bus`.readRegister(`address`, `register`)
    `bus`.writeRegister(`address`, `register`, port or (1'u8 shl `num`))

macro normal*(pin: static[ExternalPin]): untyped =
  expandRegister(0x06)
  quote do:
    let port = `bus`.readRegister(`address`, `register`)
    `bus`.writeRegister(`address`, `register`, port and (not (1'u8 shl `num`)))

macro pullup*(pin: static[ExternalPin]): untyped =
  expandRegister(0x06)
  quote do:
    let port = `bus`.readRegister(`address`, `register`)
    `bus`.writeRegister(`address`, `register`, port or (1'u8 shl `num`))

macro low*(pin: static[ExternalPin]): untyped =
  expandRegister(0x0A)
  quote do:
    let port = `bus`.readRegister(`address`, `register`)
    `bus`.writeRegister(`address`, `register`, port and (not (1'u8 shl `num`)))

macro high*(pin: static[ExternalPin]): untyped =
  expandRegister(0x0A)
  quote do:
    let port = `bus`.readRegister(`address`, `register`)
    `bus`.writeRegister(`address`, `register`, port or (1'u8 shl `num`))

macro read*(pin: static[ExternalPin]): untyped =
  expandRegister(0x09)
  quote do:
    `bus`.readRegister(`address`, `register`) and (1'u8 shl `num`)

template initMCP23017*(bus: I2c, address: uint8): untyped =
  bus.init()
  bus.writeRegister(address, 0x0A, 0b1010_0000)
