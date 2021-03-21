blinky: blinky.nim nim.cfg panicoverride.nim teensy.nim keyboard.nim
	nim c -d:danger --opt:size --os:standalone blinky

blinky.hex: blinky
	avr-objcopy -O ihex -R .eeprom blinky blinky.hex

size: blinky
	avr-size -C --mcu=atmega32u4 blinky

upload: blinky.hex
	teensy-loader-cli --mcu=TEENSY2 -v -w blinky.hex
