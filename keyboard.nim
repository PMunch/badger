import mappings/dvorak
import pgmspace, macros, teensy

const
  VENDOR_ID = 0x16C0
  PRODUCT_ID = 0x047C
  EP_TYPE_CONTROL = 0x00
  EP_TYPE_BULK_IN = 0x81
  EP_TYPE_BULK_OUT = 0x80
  EP_TYPE_INTERRUPT_IN = 0xC1
  EP_TYPE_INTERRUPT_OUT = 0xC0
  EP_TYPE_ISOCHRONOUS_IN = 0x41
  EP_TYPE_ISOCHRONOUS_OUT = 0x40
  EP_SINGLE_BUFFER = 0x02
  EP_DOUBLE_BUFFER = 0x06
  CONFIG1_DESC_SIZE = 9+9+9+7
  KEYBOARD_HID_DESC_OFFSET = 9+9
  ENDPOINT0_SIZE = 32
  KEYBOARD_INTERFACE = 0
  KEYBOARD_ENDPOINT = 3
  KEYBOARD_SIZE = 8
  KEYBOARD_BUFFER = EP_DOUBLE_BUFFER
  # standard control endpoint request types
  GET_STATUS = 0
  CLEAR_FEATURE = 1
  SET_FEATURE = 3
  SET_ADDRESS = 5
  GET_DESCRIPTOR = 6
  GET_CONFIGURATION = 8
  SET_CONFIGURATION = 9
  GET_INTERFACE = 10
  SET_INTERFACE = 11
  # HID (human interface device)
  HID_GET_REPORT = 1
  HID_GET_IDLE = 2
  HID_GET_PROTOCOL = 3
  HID_SET_REPORT = 9
  HID_SET_IDLE = 10
  HID_SET_PROTOCOL = 11
  # CDC (communication class device)
  CDC_SET_LINE_CODING = 0x20
  CDC_GET_LINE_CODING = 0x21
  CDC_SET_CONTROL_LINE_STATE = 0x22
  STR_MANUFACTURER = "MfgName"
  STR_PRODUCT = "Keyboard"
  adden = 7
  MAX_ENDPOINT = 4

template EP_SIZE(s: untyped): untyped =
  if s == 64: 0x30
  elif s == 32: 0x20
  elif s == 16: 0x10
  else: 0x00

template LSB(n: untyped): untyped = n and 255
template MSB(n: untyped): untyped = (n shr 8) and 255

{.push nodecl, header: "<avr/io.h>".}
var
  uhwCon {.importc: "UHWCON".}: uint8
  udCon {.importc: "UDCON".}: uint8
  pllCsr {.importc: "PLLCSR".}: uint8
  usbCon {.importc: "USBCON".}: uint8
  usbe {.importc: "USBE".}: uint8
  otgpade {.importc: "OTGPADE".}: uint8
  frzclk {.importc: "FRZCLK".}: uint8
  eorste {.importc: "EORSTE".}: uint8
  eorsti {.importc: "EORSTI".}: uint8
  sofe {.importc: "SOFE".}: uint8
  sofi {.importc: "SOFI".}: uint8
  plock {.importc: "PLOCK".}: uint8
  udien {.importc: "UDIEN".}: uint8
  sreg {.importc: "SREG".}: uint8
  uenum {.importc: "UENUM".}: uint8
  udfnuml {.importc: "UDFNUML".}: uint8
  ueintx {.importc: "UEINTX".}: uint8
  rwal {.importc: "RWAL".}: uint8
  uedatx {.importc: "UEDATX".}: uint8
  udint {.importc: "UDINT".}: uint8
  uecfg0x {.importc: "UECFG0X".}: uint8
  uecfg1x {.importc: "UECFG1X".}: uint8
  ueienx {.importc: "UEIENX".}: uint8
  rxstpe {.importc: "RXSTPE".}: uint8
  rxstpi {.importc: "RXSTPI".}: uint8
  ueconx {.importc: "UECONX".}: uint8
  txini {.importc: "TXINI".}: uint8
  rxouti {.importc: "RXOUTI".}: uint8
  udaddr {.importc: "UDADDR".}: uint16
  uerst {.importc: "UERST".}: uint8
  stallrq {.importc: "STALLRQ".}: uint8
  stallrqc {.importc: "STALLRQC".}: uint8
  epen {.importc: "EPEN".}: uint8
  rstdt {.importc: "RSTDT".}: uint8

template hwConfig(): untyped = uhwCon = 0x01
template pllConfig(): untyped = pllCsr = 0x12
template usbConfig(): untyped = usbCon.set usbe, otgpade
template usbFreeze(): untyped = usbCon.set usbe, frzclk
{.pop.}
{.push nodecl, header: "<avr/interrupt.h>".}
proc sei() {.importc.}
proc cli() {.importc.}
{.pop.}

template wideSize(x: static[string]): untyped = x.len * 2

macro wide(x: static[string]): untyped =
  result = nnkBracket.newTree()
  for c in x:
    result.add newLit(c.ord.int16)

type
  UsbStringDescriptor[N: static[int]] = object
    bLength: uint8
    bDescriptorType: uint8
    wString: array[N, int16]
  Descriptor {.packed.} = object
    wValue: uint16
    wIndex: uint16
    address: ptr uint8
    length: uint8

createFieldReaders(Descriptor)

#template descriptor(wValuei, wIndexi: uint16, addressi: Progmem, lengthi: int): Descriptor =
#  Descriptor(wValue: wValuei, wIndex: wIndexi, address: cast[pointer](addressi.unsafeAddr), length: uint8(lengthi))

progmem:
  endpointConfigTable = [0'u8, 0, 1, EP_TYPE_INTERRUPT_IN, EP_SIZE(KEYBOARD_SIZE) or KEYBOARD_BUFFER, 0]
  deviceDescriptor = [
    18'u8,                            # bLength
    1,                                # bDescriptorType
    0x00, 0x02,                       # bcdUSB
    0,                                # bDeviceClass
    0,                                # bDeviceSubClass
    0,                                # bDeviceProtocol
    ENDPOINT0_SIZE,                   # bMaxPacketSize0
    LSB(VENDOR_ID), MSB(VENDOR_ID),   # idVendor
    LSB(PRODUCT_ID), MSB(PRODUCT_ID), # idProduct
    0x00, 0x01,                       # bcdDevice
    1,                                # iManufacturer
    2,                                # iProduct
    0,                                # iSerialNumber
    1                                 # bNumConfigurations
  ]
  keyboardHidReportDesc = [
    0x05'u8, 0x01, # Usage Page (Generic Desktop),
    0x09, 0x06, # Usage (Keyboard),
    0xA1, 0x01, # Collection (Application),
    0x75, 0x01, #   Report Size (1),
    0x95, 0x08, #   Report Count (8),
    0x05, 0x07, #   Usage Page (Key Codes),
    0x19, 0xE0, #   Usage Minimum (224),
    0x29, 0xE7, #   Usage Maximum (231),
    0x15, 0x00, #   Logical Minimum (0),
    0x25, 0x01, #   Logical Maximum (1),
    0x81, 0x02, #   Input (Data, Variable, Absolute), ;Modifier byte
    0x95, 0x01, #   Report Count (1),
    0x75, 0x08, #   Report Size (8),
    0x81, 0x03, #   Input (Constant),                 ;Reserved byte
    0x95, 0x05, #   Report Count (5),
    0x75, 0x01, #   Report Size (1),
    0x05, 0x08, #   Usage Page (LEDs),
    0x19, 0x01, #   Usage Minimum (1),
    0x29, 0x05, #   Usage Maximum (5),
    0x91, 0x02, #   Output (Data, Variable, Absolute), ;LED report
    0x95, 0x01, #   Report Count (1),
    0x75, 0x03, #   Report Size (3),
    0x91, 0x03, #   Output (Constant),                 ;LED report padding
    0x95, 0x06, #   Report Count (6),
    0x75, 0x08, #   Report Size (8),
    0x15, 0x00, #   Logical Minimum (0),
    0x25, 0xFF, #   Logical Maximum(255),
    0x05, 0x07, #   Usage Page (Key Codes),
    0x19, 0x00, #   Usage Minimum (0),
    0x29, 0xFF, #   Usage Maximum (255),
    0x81, 0x00, #   Input (Data, Array),
    0xc0        # End Collection
  ]
  config1Descriptor: array[CONFIG1_DESC_SIZE, uint8] = [
    # configuration descriptor, USB spec 9.6.3, page 264-266, Table 9-10
    9'u8,                                   # bLength;
    2,                                      # bDescriptorType;
    LSB(CONFIG1_DESC_SIZE),                 # wTotalLength
    MSB(CONFIG1_DESC_SIZE),
    1,                                      # bNumInterfaces
    1,                                      # bConfigurationValue
    0,                                      # iConfiguration
    0xC0,                                   # bmAttributes
    50,                                     # bMaxPower
    # interface descriptor, USB spec 9.6.5, page 267-269, Table 9-12
    9,                                      # bLength
    4,                                      # bDescriptorType
    KEYBOARD_INTERFACE,                     # bInterfaceNumber
    0,                                      # bAlternateSetting
    1,                                      # bNumEndpoints
    0x03,                                   # bInterfaceClass (0x03 = HID)
    0x01,                                   # bInterfaceSubClass (0x01 = Boot)
    0x01,                                   # bInterfaceProtocol (0x01 = Keyboard)
    0,                                      # iInterface
    # HID interface descriptor, HID 1.11 spec, section 6.2.1
    9,                                      # bLength
    0x21,                                   # bDescriptorType
    0x11, 0x01,                             # bcdHID
    0,                                      # bCountryCode
    1,                                      # bNumDescriptors
    0x22,                                   # bDescriptorType
    sizeof(keyboard_hid_report_desc).uint8, # wDescriptorLength
    0,
    # endpoint descriptor, USB spec 9.6.6, page 269-271, Table 9-13
    7,                                      # bLength
    5,                                      # bDescriptorType
    KEYBOARD_ENDPOINT or 0x80,              # bEndpointAddress
    0x03,                                   # bmAttributes (0x03=intr)
    KEYBOARD_SIZE, 0,                       # wMaxPacketSize
    1                                       # bInterval
  ]
  string0 = UsbStringDescriptor[1](
    bLength: 4,
    bDescriptorType: 3,
    wString: [0x0409'i16])
  string1 = UsbStringDescriptor[STR_MANUFACTURER.len](
    bLength: wideSize(STR_MANUFACTURER) + 2,
    bDescriptorType: 3,
    wString: wide(STR_MANUFACTURER))
  string2 = UsbStringDescriptor[STR_PRODUCT.len](
    bLength: wideSize(STR_PRODUCT) + 2,
    bDescriptorType: 3,
    wString: wide(STR_PRODUCT))
#  testDescriptor = Descriptor(wValue: 0x0100, wIndex: 0x0000, address: nil, length: 0)
#
#template wIndex2(x: Progmem[Descriptor]): Progmem[uint16] =
#  Progmem[uint16](cast[int](x.unsafeAddr) + Descriptor.offsetof(wIndex))
#
#let test {.exportc.} = testDescriptor.wIndex2

{.emit:["""/*VARSECTION*/
static const """, Descriptor, """ PROGMEM descriptor_list[] = {
	{0x0100, 0x0000,""", device_descriptor, """, sizeof(""", device_descriptor, """)},
	{0x0200, 0x0000,""", config1_descriptor, """, sizeof(""", config1_descriptor, """)},
	{0x2200, """, KEYBOARD_INTERFACE, ",", keyboard_hid_report_desc, """, sizeof(""", keyboard_hid_report_desc, """)},
	{0x2100, """, KEYBOARD_INTERFACE, ",", config1_descriptor, """+""", KEYBOARD_HID_DESC_OFFSET, """, 9},
	{0x0300, 0x0000, (const uint8_t *)&""", string0, """, 4},
	{0x0301, 0x0409, (const uint8_t *)&""", string1, ", ", STR_MANUFACTURER.len + 2,"""},
	{0x0302, 0x0409, (const uint8_t *)&""", string2, ", ", STR_PRODUCT.len + 2,"""}
};"""].}

const NUM_DESC_LIST = 7
let descriptorList {.nodecl, importc: "descriptor_list".}: Progmem[array[NUM_DESC_LIST, Descriptor]]
#let descriptorList {.nodecl, importc: "descriptor_list".}: pointer

var
  # which modifier keys are currently pressed
  keyboard_modifier_keys*: Modifiers
  # which keys are currently pressed, up to 6 keys may be down at once
  keyboard_keys*: array[6, Key]
  # count until idle timeout
  keyboard_idle_count: uint8 = 0
  # zero when we are not configured, non-zero when enumerated
  usb_configuration {.volatile.}: uint8 = 0
  # protocol setting from the host.  We use exactly the same report
  # either way, so this variable only stores the setting since we
  # are required to be able to report which setting is in use.
  keyboard_protocol: uint8 = 1
  # the idle configuration, how often we send the report to the
  # host (ms * 4) even when it hasn't changed
  keyboard_idle_config: uint8 = 125
  # 1=num lock, 2=caps lock, 4=scroll lock, 8=compose, 16=kana
  keyboard_leds* {.volatile.}: uint8 = 0

proc usbInit*() =
  hwConfig()
  usbFreeze() # enable USB
  pllConfig() # config PLL
  while not pllCsr.check plock:
    discard # wait for PLL lock
  usbConfig() # start USB clock
  udcon = 0 # enable attach resistor
  usbConfiguration = 0
  udien.set eorste, sofe
  sei()

proc usbConfigured*(): uint8 = usb_configuration

proc usbKeyboardSend*(): int8

proc usbKeyboardPress*(key: Key, modifier: Modifiers): int8 =
  keyboardModifierKeys = modifier
  keyboardKeys[0] = key
  let r = usbKeyboardSend()
  if r != 0: return r
  keyboardModifierKeys = MOD_NONE
  keyboardKeys[0] = KEY_NONE
  return usbKeyboardSend()

proc usbKeyboardSend*(): int8 =
  if usb_configuration == 0: return -1
  var intr_state = sreg
  cli()
  uenum = KEYBOARD_ENDPOINT
  var timeout = udfnuml + 50
  while true:
    # are we ready to transmit?
    if ueintx.check rwal: break
    sreg = intr_state
    # has the USB gone offline?
    if usb_configuration == 0: return -1
    # have we waited too long?
    if udfnuml == timeout: return -1
    # get ready to try checking again
    intr_state = sreg
    cli()
    uenum = KEYBOARD_ENDPOINT
  uedatx = keyboard_modifier_keys.uint8
  uedatx = 0
  for key in keyboardKeys:
    uedatx = key.uint8
  ueintx = 0x3A
  keyboard_idle_count = 0
  sreg = intr_state
  return 0

proc deviceInterrupt() {.codegenDecl: "ISR(USB_GEN_vect)", exportc.} =
  var
    intbits: uint8
    div4 {.global.} = 0'u8
  intbits = udint
  udint = 0
  if intbits.check eorsti:
    uenum = 0
    ueconx = 1
    uecfg0x = EP_TYPE_CONTROL
    uecfg1x = EP_SIZE(ENDPOINT0_SIZE) or EP_SINGLE_BUFFER
    ueienx.set rxstpe
    usbConfiguration = 0
  if intbits.check(sofi) and usbConfiguration != 0:
    inc div4
    if keyboard_idle_config != 0 and ((div4 and 3) == 0):
      uenum = KEYBOARD_ENDPOINT
      if ueintx.check rwal:
        inc keyboard_idle_count
        if (keyboard_idle_count == keyboard_idle_config):
          keyboard_idle_count = 0
          uedatx = keyboard_modifier_keys.uint8
          uedatx = 0
          for key in keyboardKeys:
            uedatx = key.uint8
          ueintx = 0x3A

# Misc functions to wait for ready and send/receive packets
template usb_wait_in_ready(): untyped =
  while not ueintx.check(txini): discard
template usb_send_in(): untyped =
  ueintx.unset txini
template usb_wait_receive_out(): untyped =
  while not ueintx.check(rxouti): discard
template usb_ack_out(): untyped =
  ueintx.unset rxouti

template doWhile(body, cond: untyped): untyped =
  var cont = true
  while cont:
    body
    cont = cond

# USB Endpoint Interrupt - endpoint 0 is handled here.  The
# other endpoints are manipulated by the user-callable
# functions, and the start-of-frame interrupt.
proc endpointInterrupt() {.codegenDecl: "ISR(USB_COM_vect)", exportc.} =
  uenum = 0
  var intbits = ueintx
  if intbits.check(rxstpi):
    var bmRequestType = uedatx
    var bRequest = uedatx
    var wValue = uedatx.uint16 or (uedatx.uint16 shl 8'u16)
    var wIndex = uedatx.uint16 or (uedatx.uint16 shl 8'u16)
    var wLength = uedatx.uint16 or (uedatx.uint16 shl 8'u16)
    ueintx.unset rxstpi, rxouti, txini
    if bRequest == GET_DESCRIPTOR:
      var
        desc_addr: ptr uint8
        desc_length: uint8
      for i in 0..descriptorList.len:
        if i == descriptorList.len:
          ueconx.set stallrq, epen
          return
        var descVal = descriptorList[i].wValue
        if descVal != wValue:
          continue
        descVal = descriptorList[i].wIndex
        if descVal != wIndex:
          continue
        descAddr = descriptorList[i].address
        descLength = descriptorList[i].length
        break
      var length = uint8(if wLength < 256: wLength else: 255)
      if length > desc_length: length = desc_length
      doWhile:
        var i: uint8
        doWhile:
          i = ueintx
        do: not i.check(txini, rxouti)
        if i.check rxouti: return
        var n = if length < ENDPOINT0_SIZE: length else: ENDPOINT0_SIZE
        for i in countdown(n, 1):
          uedatx = pgm_read_byte(desc_addr)
          desc_addr = cast[ptr uint8](cast[int](desc_addr) + 1)
        length -= n
        usb_send_in()
      do: length != 0 or n == ENDPOINT0_SIZE
      return
    if bRequest == SET_ADDRESS:
      usb_send_in()
      usb_wait_in_ready()
      udaddr = wValue or (1'u16 shl adden)
      return
    if bRequest == SET_CONFIGURATION and bmRequestType == 0:
      usb_configuration = uint8(wValue)
      usb_send_in()
      var cfg = cast[ptr uint8](endpointConfigTable.unsafeAddr)
      for i in 1'u8..<5:
        uenum = i
        var en = pgmReadByte(cfg)
        cfg = cast[ptr uint8](cast[int](cfg) + 1)
        ueconx = en
        if en != 0:
          uecfg0x = pgmReadByte(cfg)
          cfg = cast[ptr uint8](cast[int](cfg) + 1)
          uecfg1x = pgmReadByte(cfg)
          cfg = cast[ptr uint8](cast[int](cfg) + 1)
      uerst = 0x1E
      uerst = 0
      return
    if bRequest == GET_CONFIGURATION and bmRequestType == 0x80:
      usb_wait_in_ready()
      uedatx = usb_configuration
      usb_send_in()
      return
    if bRequest == GET_STATUS:
      usb_wait_in_ready()
      var i = 0'u8
      when defined(SUPPORT_ENDPOINT_HALT):
        if (bmRequestType == 0x82):
          uenum = uint8(wIndex)
          if ueconx.check stallrq:
            i = 1
          uenum = 0
      uedatx = i
      uedatx = 0
      usb_send_in()
      return
    when defined(SUPPORT_ENDPOINT_HALT):
      if (bRequest == CLEAR_FEATURE and bRequest == SET_FEATURE) and
          bmRequestType == 0x02 and wValue == 0:
        var i = uint8(wIndex and 0x7F)
        if i >= 1 and i <= MAX_ENDPOINT:
          usb_send_in()
          uenum = i
          if bRequest == SET_FEATURE:
            ueconx.set stallrq, epen
          else:
            ueconx.set stallrqc, rstdt, epen
            uerst.set i
            uerst = 0
          return
    if wIndex == KEYBOARD_INTERFACE:
      if bmRequestType == 0xA1:
        if bRequest == HID_GET_REPORT:
          usb_wait_in_ready()
          uedatx = keyboard_modifier_keys.uint8
          uedatx = 0
          for key in keyboardKeys:
            uedatx = key.uint8
          usb_send_in()
          return
        if bRequest == HID_GET_IDLE:
          usb_wait_in_ready()
          uedatx = keyboard_idle_config
          usb_send_in()
          return
        if bRequest == HID_GET_PROTOCOL:
          usb_wait_in_ready()
          uedatx = keyboard_protocol
          usb_send_in()
          return
      if bmRequestType == 0x21:
        if bRequest == HID_SET_REPORT:
          usb_wait_receive_out()
          keyboard_leds = uedatx
          usb_ack_out()
          usb_send_in()
          return
        if bRequest == HID_SET_IDLE:
          keyboard_idle_config = uint8(wValue shr 8'u16)
          keyboard_idle_count = 0
          usb_send_in()
          return
        if bRequest == HID_SET_PROTOCOL:
          keyboard_protocol = uint8(wValue)
          usb_send_in()
          return
  ueconx.set stallrq, epen # stall
