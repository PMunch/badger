import macros

{.push nodecl, header: "<avr/pgmspace.h>".}
type Progmem*[T] = distinct T

proc pgmReadByte*[T](address: ptr T): T {.importc: "pgm_read_byte".}

converter read*[T](data: Progmem[T]): T =
  pgmReadByte(cast[ptr T](data.unsafeAddr))

template `[]`*[N, T](data: Progmem[array[N, T]], idx: int): untyped =
  pgmReadByte(array[N, T](data)[idx].unsafeAddr)

macro progmem*(definitions: untyped): untyped =
  result = nnkLetSection.newTree()
  for definition in definitions:
    let data = definition[1]
    result.add nnkIdentDefs.newTree(
        nnkPragmaExpr.newTree(
          definition[0],
          nnkPragma.newTree(nnkExprColonExpr.newTree(
              newIdentNode("codegenDecl"),
              newLit("N_LIB_PRIVATE NIM_CONST $# PROGMEM $#")
            ))),
        newEmptyNode(),
        quote do:
          Progmem(`data`)
        )
  echo result.repr
{.pop.}
