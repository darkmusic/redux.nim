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

macro dispatchAction*(storename: Store, actiontypename: untyped): untyped =
  result = newStmtList()

  var varSection = newNimNode(nnkVarSection)
  var identDefs = newNimNode(nnkIdentDefs)
  var identNode1 = newIdentNode("action")
  identDefs.add(identNode1)
  var emptyNode = newNimNode(nnkEmpty)
  identDefs.add(emptyNode)
  var objConstr = newNimNode(nnkObjConstr)
  var identNode2 = newIdentNode($actiontypename)
  objConstr.add(identNode2)
  var exprColonExpr = newNimNode(nnkExprColonExpr)
  exprColonExpr.add(newIdentNode("Name"))
  exprColonExpr.add(newStrLitNode($actiontypename))
  objConstr.add(exprColonExpr)
  identDefs.add(objConstr)
  varSection.add(identDefs)
  result.add(varSection)

  var callNode = newNimNode(nnkCall)
  var dotExprNode = newNimNode(nnkDotExpr)
  dotExprNode.add(newIdentNode($storename))
  dotExprNode.add(newIdentNode("dispatch"))
  callNode.add(dotExprNode)
  callNode.add(newIdentNode("action"))
  result.add(callNode)
