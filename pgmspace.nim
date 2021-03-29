import macros

{.push nodecl, header: "<avr/pgmspace.h>".}
type Progmem*[T] = distinct T

proc pgmReadByte*[T](address: ptr T): T {.importc: "pgm_read_byte".}

converter read*[T](data: Progmem[T]): T =
  pgmReadByte(cast[ptr T](data.unsafeAddr))

template `[]`*[N, T](data: Progmem[array[N, T]], idx: int): untyped =
  pgmReadByte(array[N, T](data)[idx].unsafeAddr)

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
      template `name`(): untyped = Progmem(`hiddenName`)
  #echo result.repr
{.pop.}
