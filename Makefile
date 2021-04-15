i2ctest: i2ctest.nim nim.cfg panicoverride.nim teensy.nim i2c.nim mcp23017.nim
	nim c -d:danger --opt:size --os:any i2ctest

i2ctest.hex: i2ctest
	avr-objcopy -O ihex -R .eeprom i2ctest i2ctest.hex

size: i2ctest
	avr-size -C --mcu=atmega32u4 i2ctest

size-breakdown: i2ctest
	avr-size -C --mcu=atmega32u4 i2ctest
	@echo ".data section:"
	avr-nm -S --size-sort i2ctest | grep " [Dd] " || echo "empty"
	@echo ""
	@echo ".bss section:"
	avr-nm -S --size-sort i2ctest | grep " [Bb] " || echo "empty"
	@echo ""
	@echo ".text section:"
	avr-nm -S --size-sort i2ctest | grep " [Tt] " || echo "empty"

upload: i2ctest.hex
	teensy-loader-cli --mcu=TEENSY2 -v -w i2ctest.hex
