import macros, hashes
import i2c
export i2c

type
  ExternalPin* = object
    bus: I2c
    address: uint8
    port: ExternalPort
    num: int
  ExternalPort* = distinct uint8

proc `==`(a, b: ExternalPort): bool {.borrow.}
proc `hash`(a: ExternalPort): Hash {.borrow.}

proc pin(address: uint8, bus: I2c, port: ExternalPort, num: int): ExternalPin {.compileTime.} =
  ExternalPin(address: address, port: port, num: num)

const
  PortA* = ExternalPort(0x00'u8)
  PortB* = ExternalPort(0x10'u8)

template defineMCP23017*(address: uint8, bus: I2c, prefix: untyped): untyped =
  const
    `prefix A0`* {.inject.} = pin(address, bus, PortA, 0)
    `prefix A1`* {.inject.} = pin(address, bus, PortA, 1)
    `prefix A2`* {.inject.} = pin(address, bus, PortA, 2)
    `prefix A3`* {.inject.} = pin(address, bus, PortA, 3)
    `prefix A4`* {.inject.} = pin(address, bus, PortA, 4)
    `prefix A5`* {.inject.} = pin(address, bus, PortA, 5)
    `prefix A6`* {.inject.} = pin(address, bus, PortA, 6)
    `prefix A7`* {.inject.} = pin(address, bus, PortA, 7)
    `prefix B0`* {.inject.} = pin(address, bus, PortB, 0)
    `prefix b1`* {.inject.} = pin(address, bus, PortB, 1)
    `prefix B2`* {.inject.} = pin(address, bus, PortB, 2)
    `prefix B3`* {.inject.} = pin(address, bus, PortB, 3)
    `prefix B4`* {.inject.} = pin(address, bus, PortB, 4)
    `prefix B5`* {.inject.} = pin(address, bus, PortB, 5)
    `prefix B6`* {.inject.} = pin(address, bus, PortB, 6)
    `prefix B7`* {.inject.} = pin(address, bus, PortB, 7)

template expandRegister(registerAddress: uint8): untyped {.dirty.} =
  let
    register = newLit(registerAddress or uint8(pin.port))
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
  #bus.init()
  bus.writeRegister(address, 0x0A, 0b1010_0000)

import tables

macro configure*(pins: static[openarray[ExternalPin]], states: varargs[untyped]): untyped =
  result = newStmtList()
  var busAddressedPorts: Table[I2C, Table[uint8, Table[ExternalPort, seq[int]]]]
  for pin in pins:
    busAddressedPorts.mgetOrPut(pin.bus, initTable[uint8, Table[ExternalPort, seq[int]]]()).mgetOrPut(pin.address, initTable[ExternalPort, seq[int]]()).mgetOrPut(pin.port, @[]).add pin.num
  for state in states:
    expectKind state, nnkIdent
    for bus, addressedPorts in busAddressedPorts:
      for address, ports in addressedPorts:
        for portName, pins in ports.pairs:
          var valueMask = newLit(0)
          for pin in pins:
            valueMask = quote do:
              `valueMask` or (1'u8 shl `pin`)
          case state.strVal:
          of "input":
            let register = newLit(0x00'u8 or uint8(portName))
            result.add quote do:
              let port = `bus`.readRegister(`address`, `register`)
              `bus`.writeRegister(`address`, `register`, port or `valueMask`)
          of "output":
            let register = newLit(0x00'u8 or uint8(portName))
            result.add quote do:
              let port = `bus`.readRegister(`address`, `register`)
              `bus`.writeRegister(`address`, `register`, port and not `valueMask`)
          of "pullup":
            let register = newLit(0x06'u8 or uint8(portName))
            result.add quote do:
              let port = `bus`.readRegister(`address`, `register`)
              `bus`.writeRegister(`address`, `register`, port or `valueMask`)
          of "normal":
            let register = newLit(0x06'u8 or uint8(portName))
            result.add quote do:
              let port = `bus`.readRegister(`address`, `register`)
              `bus`.writeRegister(`address`, `register`, port and not `valueMask`)
          of "high":
            let register = newLit(0x0A'u8 or uint8(portName))
            result.add quote do:
              let port = `bus`.readRegister(`address`, `register`)
              `bus`.writeRegister(`address`, `register`, port or `valueMask`)
          of "low":
            let register = newLit(0x0A'u8 or uint8(portName))
            result.add quote do:
              let port = `bus`.readRegister(`address`, `register`)
              `bus`.writeRegister(`address`, `register`, port and not `valueMask`)
          else: doAssert state.strVal in ["input", "output", "pullup", "normal", "high", "low"]
  #echo result.repr
