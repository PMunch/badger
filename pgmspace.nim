import macros

{.push nodecl, header: "<avr/pgmspace.h>".}
type Progmem*[T] = distinct T

proc pgmReadByte*[T](address: ptr T): uint8 {.importc: "pgm_read_byte".}
proc pgmReadWord*[T](address: ptr T): uint16 {.importc: "pgm_read_word".}
proc pgmReadDoubleWord*[T](address: ptr T): uint32 {.importc: "pgm_read_dword".}
proc memcpyPgm*[T](dest: ptr T, src: ptr T, size: csize_t): ptr T {.importc: "memcpy_P".}
{.pop.}

template read*[T](data: Progmem[T]): T =
  cast[T](
    when sizeof(T) == 1:
      pgmReadByte(cast[ptr T](data.unsafeAddr))
    elif sizeof(T) == 2:
      pgmReadWord(cast[ptr T](data.unsafeAddr))
    elif sizeof(T) == 4:
      pgmReadDoubleWord(cast[ptr T](data.unsafeAddr))
    else:
      var x: T
      memcpyPgm(x.addr, cast[ptr T](data.unsafeAddr), sizeof(T))[])

template `[]`*[N, T](data: Progmem[array[N, T]], idx: int): untyped =
  read(Progmem(array[N, T](data)[idx]))

macro progmem*(definitions: untyped): untyped =
  result = newStmtList()
  for definition in definitions:
    let
      hiddenName = genSym(nskLet)
      name = definition[0]
      data = definition[1]
    result.add quote do:
      # Stupid workaround for https://github.com/nim-lang/Nim/issues/17497
      let `hiddenName` {.codegenDecl: "N_LIB_PRIVATE NIM_CONST $# PROGMEM $#".} = `data`
      template `name`*(): untyped = Progmem(`hiddenName`)
  #echo result.repr
