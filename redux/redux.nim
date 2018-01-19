import macros

type
  Action* = ref object of RootObj
    Name*: string
  Reducer* [S] = proc (state: S = nil; action: Action = nil): S
  Subscriber* [S] = proc (state: S, action: Action)
  Store [S] = ref object {.requiresInit.}
    state: S
    reducer: Reducer[S]
    subscribers: seq[Subscriber[S]]

proc newStore*[S](reducer: Reducer[S]): Store[S] =
  Store[S](
    state: reducer(),
    reducer: reducer,
    subscribers: @[]
  )

proc getState*[S](store: Store[S]): S =
  store.state

proc subscribe*[S](store: Store[S], subscriber: Subscriber[S]) =
  store.subscribers.add(subscriber)

proc unsubscribe*[S](store: Store[S], subscriber: Subscriber[S]) =
  for index, s in pairs(store.subscribers):
    if s == subscriber:
      store.subscribers.del(index)
      break

proc dispatch*(store: Store, action: Action) =
  store.state = store.reducer(state=store.state, action=action)
  for subscriber in store.subscribers:
    subscriber(store.state, action)

macro dispatchAction*(storename: Store, statements: untyped): untyped =
  result = newStmtList()

  #echo statements.treeRepr()
  
  var actiontypename = ""
  
  if statements.len == 0:
    actiontypename = $statements
  elif statements[0].kind == nnkIdent:
    actiontypename = $statements[0]
  elif statements[0].kind == nnkCall:
    actiontypename = $statements[0][0]
  elif statements[0].kind == nnkObjConstr:
    actiontypename = $statements[0][0]

  var objConstr = newNimNode(nnkObjConstr)
  objConstr.add(newIdentNode(actiontypename))
  var exprColonExpr = newNimNode(nnkExprColonExpr)
  exprColonExpr.add(newIdentNode("Name"))
  exprColonExpr.add(newStrLitNode(actiontypename))
  objConstr.add(exprColonExpr)
  
  # Add additional parameters
  if statements.len > 0:
    for i in 1..statements.len - 1:
      let statement = statements[i]
      objConstr.add(statement)

  var callNode = newNimNode(nnkCall)
  var dotExprNode = newNimNode(nnkDotExpr)
  dotExprNode.add(newIdentNode($storename))
  dotExprNode.add(newIdentNode("dispatch"))
  callNode.add(dotExprNode)
  callNode.add(objConstr)
  result.add(callNode)

  #echo result.treeRepr()
