import teensy, hashes

type I2c* = object
const I2cBus* = I2c()

proc hash*(bus: I2c): Hash =
  Hash(0)

proc init*(bus: static[I2c]) =
  # SCL frequence = CPU frequency / (16 + (2 * TWBR * prescaler))
  # TWBR = (cpu / scl - 16) / 2
  twsr = 0x00
  twbr = 0x0C
  twcr.set twen, twint

proc start*(_: static[I2c]) =
  twcr.set twen, twint, twsta
  while not twcr.check twint: discard

proc stop*(_: static[I2c]) {.noinline.} =
  twcr.set twen, twint, twsto
  delayLoop(1'u8)
  #delayUs(100)

proc send*(_: static[I2c], data: uint8) =
  twdr = data
  twcr.set twen, twint
  while not twcr.check twint: discard

proc recv*(_: static[I2c], ack: static[bool]): uint8 =
  when ack:
    twcr.set twen, twint, twea
  else:
    twcr.set twen, twint
  while not twcr.check twint: discard
  return twdr

proc writeRegister*(bus: static[I2c], address, register, data: uint8) =
  bus.start()
  bus.send(address)
  bus.send(register)
  bus.send(data)
  bus.stop()

proc readRegister*(bus: static[I2c], address, register: uint8): uint8 =
  bus.start()
  bus.send(address)
  bus.send(register)
  bus.stop()

  bus.start()
  bus.send(address or 0x01)
  result = bus.recv(false)
  bus.stop()
