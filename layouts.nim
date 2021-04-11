import macros

var
  callbackId {.compileTime.} = 231
  callbacks {.compileTime.}: seq[NimNode]

macro expandKey(key: typed): untyped =
  #echo key.treeRepr
  #if key.kind == nnkCall:
  #  let typeImpl = key[0].getTypeImpl
  #  if typeImpl.kind == nnkProcTy:
  #    inc callbackId
  #    callbacks.add key
  #    quote do:
  #      Key(`callbackId`)
  #  else:
  #    key
  if key.kind != nnkSym:
    inc callbackId
    callbacks.add key
    quote do:
      Key(`callbackId`)
  else:
    key

#macro generateCallbacks(startId: int): untyped =


#macro layoutCallback(key: untyped): untyped =
  #quote do:
  #  case(`key`.uint8):
  #  of 232: `callbacks[0]`()
macro layoutCallback*(key: untyped): untyped =
  result = quote do:
    case (`key`.uint8):
    else: discard
  #result.del 1
  for i, callback in callbacks:
    result.add nnkOfBranch.newTree(newLit(232 + i), callback)
  #echo result.repr

macro createLayout*(name: untyped, x: untyped): untyped =
  let startCallbacks = callbackId
  result = newStmtList()
  #echo x.treeRepr
  var keys = nnkBracket.newTree()
  proc addKey(key: NimNode) =
    #echo key.treeRepr
    if key.kind == nnkIdent:
      let keySym = newIdentNode("KEY_" & key.strVal)
      keys.add quote do:
        when declared(`key`): expandKey(`key`) else: `keySym`
    elif key.kind == nnkIntLit:
      let keySym = newIdentNode("KEY_" & $key.intVal)
      keys.add keySym
    else:
      keys.add quote do:
        expandKey(`key`)
  for row in x:
    var column = row
    while column.kind == nnkCommand:
      addKey column[0]
      column = column[1]
    addKey column
  #echo keys.repr
  result = quote do:
    progmem:
      `name` = `keys`
    #generateCallbacks(`startCallbacks`)
  #echo result.repr
