badger: badger.nim nim.cfg teensy.nim keyboard.nim pgmspace.nim layouts.nim mappings/dvorak.nim mappings/qwerty.nim mcp23017.nim
	nim c -d:danger --opt:size --os:any badger

badger.hex: badger
	avr-objcopy -O ihex -R .eeprom badger badger.hex

size: badger
	avr-size -C --mcu=atmega32u4 badger

size-breakdown: badger
	avr-size -C --mcu=atmega32u4 badger
	@echo ".data section:"
	avr-nm -S --size-sort badger | grep " [Dd] " || echo "empty"
	@echo ""
	@echo ".bss section:"
	avr-nm -S --size-sort badger | grep " [Bb] " || echo "empty"
	@echo ""
	@echo ".text section:"
	avr-nm -S --size-sort badger | grep " [Tt] " || echo "empty"

upload: badger.hex
	teensy-loader-cli --mcu=TEENSY2 -v -w badger.hex
