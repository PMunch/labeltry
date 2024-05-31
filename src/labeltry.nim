import macros

macro buildEnum(x: static seq[string]): untyped =
  result = nnkTypeSection.newTree(
    nnkTypeDef.newTree(
      newIdentNode("Label"),
      newEmptyNode(),
      nnkEnumTy.newTree(
        newEmptyNode(),
        newIdentNode("NoLabel")
      )
    )
  )
  for label in x:
    result[0][2].add newIdentNode(label)
  #echo result.repr

macro labeledTry*(body: untyped, branches: varargs[untyped]): untyped =
  let
    labels = genSym(nskVar)
    raisedLabel = genSym(nskVar)
    pipeArrow = nnkAccQuoted.newTree(newIdentNode("|>"))
  result = nnkBlockStmt.newTree(newEmptyNode(), newStmtList(quote do:
    var
      `labels` {.compileTime, global.}: seq[string]
      `raisedLabel` = -1
  ))
  result[1].add nnkTryStmt.newTree(quote do:
    template tryAndLabel(body, idx: untyped): untyped =
      try:
        body
      except:
        `raisedLabel` = idx
        raise
    macro label(x, body: untyped): untyped =
      var idx = `labels`.find(x.strVal)
      if idx == -1:
        idx = `labels`.len
        `labels`.add x.strVal
      getAst(tryAndLabel(body, idx))
    template `pipeArrow`(body, x: untyped): untyped = label(x, body)
    `body`
  )
  for branch in branches:
    var branch = branch
    branch[^1].insert(0, quote do:
      buildEnum(`labels`)
      template getLabel(): untyped {.used.} =
        Label(`raisedLabel` + 1)
    )
    result[1][^1].add branch
  #echo result.repr
