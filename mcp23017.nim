import macros, hashes
import i2c
export i2c

type
  Mcp23017Device = object
    bus: I2c
    address: uint8
  ExternalPort = object
    device: Mcp23017Device
    portNum: uint8
  ExternalPin = object
    port: ExternalPort
    num: int
  PortData = distinct uint8

proc hash(a: ExternalPort): Hash =
  hash(a.portNum)

proc pin(port: ExternalPort, num: int): ExternalPin {.compileTime.} =
  ExternalPin(num: num, port: port)

template raw*(portData: PortData): uint8 = portData.uint8

template `[]`*(portData: PortData, idx: int): uint8 =
  # TODO: add in static list of available pins on a port?
  portData.uint8 and (1'u8 shl idx)

template defineMCP23017*(i2caddress: uint8, i2cbus: I2c, prefix: untyped): untyped =
  const
    `prefix Device`* {.inject.} = Mcp23017Device(bus: i2cbus, address: i2caddress)
    `prefix PortA`* {.inject.} = ExternalPort(device: `prefix Device`, portNum: 0x00'u8)
    `prefix PortB`* {.inject.} = ExternalPort(device: `prefix Device`, portNum: 0x10'u8)
    `prefix A0`* {.inject.} = pin(`prefix PortA`, 0)
    `prefix A1`* {.inject.} = pin(`prefix PortA`, 1)
    `prefix A2`* {.inject.} = pin(`prefix PortA`, 2)
    `prefix A3`* {.inject.} = pin(`prefix PortA`, 3)
    `prefix A4`* {.inject.} = pin(`prefix PortA`, 4)
    `prefix A5`* {.inject.} = pin(`prefix PortA`, 5)
    `prefix A6`* {.inject.} = pin(`prefix PortA`, 6)
    `prefix A7`* {.inject.} = pin(`prefix PortA`, 7)
    `prefix B0`* {.inject.} = pin(`prefix PortB`, 0)
    `prefix B1`* {.inject.} = pin(`prefix PortB`, 1)
    `prefix B2`* {.inject.} = pin(`prefix PortB`, 2)
    `prefix B3`* {.inject.} = pin(`prefix PortB`, 3)
    `prefix B4`* {.inject.} = pin(`prefix PortB`, 4)
    `prefix B5`* {.inject.} = pin(`prefix PortB`, 5)
    `prefix B6`* {.inject.} = pin(`prefix PortB`, 6)
    `prefix B7`* {.inject.} = pin(`prefix PortB`, 7)

macro eachIt*(pins: static[openArray[ExternalPin]], body: untyped): untyped =
  result = newStmtList()
  let it = newIdentNode("it")
  for pin in pins:
    result.add quote do:
      block:
        const `it` = `pin`
        `body`

template expandPort(registerAddress: uint8): untyped {.dirty.} =
  let
    register = newLit(registerAddress or uint8(port.portNum))
    address = newLit(port.device.address)
    bus = newLit(port.device.bus)

template expandPin(): untyped {.dirty.} =
  let
    port = pin.port
    mask = newLit(1'u8 shl pin.num)

macro direction*(port: static[ExternalPort]): untyped =
  expandPort(0x00)
  quote do:
    `bus`.readRegister(`address`, `register`)

macro direction*(pin: static[ExternalPin]): untyped =
  expandPin()
  quote do:
    direction(`port`) and `mask`

macro resistor*(port: static[ExternalPort]): untyped =
  expandPort(0x06)
  quote do:
    `bus`.readRegister(`address`, `register`)

macro resistor*(pin: static[ExternalPin]): untyped =
  expandPin()
  quote do:
    resistor(`port`) and `mask`

macro state*(port: static[ExternalPort]): untyped =
  expandPort(0x0A)
  quote do:
    `bus`.readRegister(`address`, `register`)

macro state*(pin: static[ExternalPin]): untyped =
  expandPin()
  quote do:
    state(`port`) and `mask`

macro output*(port: static[ExternalPort], mask = 0xff'u8): untyped =
  expandPort(0x00)
  quote do:
    `bus`.writeRegister(`address`, `register`, not `mask`)

macro output*(pin: static[ExternalPin]): untyped =
  expandPin()
  quote do:
    `port`.output((not `port`.direction()) or `mask`)

macro input*(port: static[ExternalPort], mask = 0xff'u8): untyped =
  expandPort(0x00)
  quote do:
    `bus`.writeRegister(`address`, `register`, `mask`)

macro input*(pin: static[ExternalPin]): untyped =
  expandPin()
  quote do:
    `port`.input(`port`.direction() or `mask`)

macro normal*(port: static[ExternalPort], mask = 0xff'u8): untyped =
  expandPort(0x06)
  quote do:
    `bus`.writeRegister(`address`, `register`, not `mask`)

macro normal*(pin: static[ExternalPin]): untyped =
  expandPin()
  quote do:
    `port`.normal((not `port`.resistor()) or `mask`)

macro pullup*(port: static[ExternalPort], mask = 0xff'u8): untyped =
  expandPort(0x06)
  quote do:
    `bus`.writeRegister(`address`, `register`, `mask`)

macro pullup*(pin: static[ExternalPin]): untyped =
  expandPin()
  quote do:
    `port`.pullup(`port`.resistor() or `mask`)

macro low*(port: static[ExternalPort], mask = 0xff'u8): untyped =
  expandPort(0x0A)
  quote do:
    `bus`.writeRegister(`address`, `register`, not `mask`)

macro low*(pin: static[ExternalPin]): untyped =
  expandPin()
  quote do:
    `port`.low((not `port`.state()) or `mask`)

macro high*(port: static[ExternalPort], mask = 0xff'u8): untyped =
  expandPort(0x0A)
  quote do:
    `bus`.writeRegister(`address`, `register`, `mask`)

macro high*(pin: static[ExternalPin]): untyped =
  expandPin()
  quote do:
    `port`.high(`port`.state() or `mask`)

macro read*(port: static[ExternalPort]): untyped =
  expandPort(0x09)
  quote do:
    PortData(`bus`.readRegister(`address`, `register`))

macro read*(pin: static[ExternalPin]): untyped =
  expandPin()
  quote do:
    `port`.read().raw and `mask`

template initMCP23017*(bus: I2c, address: uint8): untyped =
  #bus.init()
  bus.writeRegister(address, 0x0A, 0b1010_0000)

import tables

macro configure*(pins: static[openarray[ExternalPin]], states: varargs[untyped]): untyped =
  result = newStmtList()
  var busAddressedPorts: Table[I2C, Table[uint8, Table[ExternalPort, seq[int]]]]
  for pin in pins:
    busAddressedPorts.mgetOrPut(pin.port.device.bus, initTable[uint8, Table[ExternalPort, seq[int]]]()).mgetOrPut(pin.port.device.address, initTable[ExternalPort, seq[int]]()).mgetOrPut(pin.port, @[]).add pin.num
  for state in states:
    expectKind state, nnkIdent
    for bus, addressedPorts in busAddressedPorts:
      for address, ports in addressedPorts:
        for port, pins in ports.pairs:
          let portName = port.portNum
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
