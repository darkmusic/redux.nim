import times, os, strutils, macros
import unittest
import parsecfg, base64, typetraits, redux, undoable

type 
  ClientStateObj = object
  ClientState = ref ClientStateObj
  TestObj = object
    Width: int

  TestAction = ref object of Action
    Color: string
    Height: int
    MyObj: TestObj
    Foo: string

{.experimental.}
using
  state: ClientState
  action: Action

proc domaction(state, action): ClientState =
  if state == nil:
    return ClientState()
      
  return state

var actionName: string

proc printInfo(state: UndoableState[ClientState], action: Action) =
  echo "Action name: $1" % action.Name
  actionName = action.Name

macro rewriteTest(statements: untyped): untyped =
  result = newStmtList()

  echo statements.treeRepr()
  
suite "Redux Tests":
  var store = newStore(undoable(domaction))
  store.subscribe(printInfo)

  test "Parameterless subscriber action name test":
    store.dispatchAction(TestAction)
    doAssert actionName == "TestAction"

  test "Rewrite test":
    rewriteTest:
      store.dispatchAction(TestAction(Name: "TestAction"))

  test "Parameterless subscriber action name test with parens":
    store.dispatchAction(TestAction())
    doAssert actionName == "TestAction"
  
  test "Single parameter subscriber action name test":
    store.dispatchAction(TestAction(Color:"green"))
    doAssert actionName == "TestAction"

  test "Multiple parameter subscriber action name test":
    store.dispatchAction(TestAction(Color:"green", Height: 800, MyObj: TestObj(Width: 600), Foo: """bar"""))
    doAssert actionName == "TestAction"
