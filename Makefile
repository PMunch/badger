badger: badger.nim nim.cfg panicoverride.nim teensy.nim keyboard.nim
	nim c -d:danger --opt:size --os:standalone badger

badger.hex: badger
	avr-objcopy -O ihex -R .eeprom badger badger.hex

size: badger
	avr-size -C --mcu=atmega32u4 badger

upload: badger.hex
	teensy-loader-cli --mcu=TEENSY2 -v -w badger.hex
