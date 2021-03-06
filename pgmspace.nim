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
      memcpyPgm(x.addr, cast[ptr T](data.unsafeAddr), sizeof(T).csize_t)[])

template len*[N, T](data: Progmem[array[N, T]]): untyped =
  array[N, T](data).len

template `[]`*[N, T](data: Progmem[array[N, T]], idx: int): untyped =
  when T isnot object:
    read(Progmem(array[N, T](data)[idx]))
  else:
    Progmem(array[N, T](data)[idx])

macro createFieldReaders*(obj: typed): untyped =
  let impl = getImpl(obj)
  doAssert(impl.kind == nnkTypeDef)
  doAssert(impl[2].kind == nnkObjectTy)
  result = newStmtList()
  for def in impl[2][2]:
    let
      name = def[0]
      kind = def[1]
    result.add quote do:
      template `name`(x: Progmem[`obj`]): `kind` =
        cast[`kind`](
          when sizeof(`kind`) == 1:
            pgmReadByte(cast[ptr uint8](cast[int](x.unsafeAddr) + `obj`.offsetof(`name`)))
          elif sizeof(`kind`) == 2:
            pgmReadWord(cast[ptr uint16](cast[int](x.unsafeAddr) + `obj`.offsetof(`name`)))
          elif sizeof(`kind`) == 4:
            pgmReadDoubleWord(cast[ptr uint32](cast[int](x.unsafeAddr) + `obj`.offsetof(`name`)))
          else:
            var x: T
            memcpyPgm(x.addr, cast[ptr T](data.unsafeAddr), sizeof(T).csize_t)[])

macro progmem*(definitions: untyped): untyped =
  #echo definitions.treeRepr
  result = newStmtList()
  for definition in definitions:
    var
      hiddenName: NimNode
      name: NimNode
      data: NimNode
      dataType = newIdentNode("auto")
    case definition.kind:
    of nnkAsgn:
      hiddenName = genSym(nskLet, definition[0].strVal)
      name = definition[0]
      data = definition[1]
    of nnkCall:
      hiddenName = genSym(nskLet, definition[0].strVal)
      name = definition[0]
      dataType = definition[1][0][0]
      data = definition[1][0][1]
    else: discard
    result.add quote do:
      # Stupid workaround for https://github.com/nim-lang/Nim/issues/17497
      let `hiddenName` {.codegenDecl: "N_LIB_PRIVATE NIM_CONST $# PROGMEM $#".}: `dataType` = `data`
      template `name`*(): untyped = Progmem(`hiddenName`)
  #echo result.repr
