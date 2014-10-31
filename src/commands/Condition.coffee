Command = require('../concepts/Command')

class Condition extends Command
  type: 'Condition'
  
  signature: [
  	if: ['Query', 'Value', 'Constraint'],
  	then: null, 
  	[
  		else: null
  	]
  ]

  cleaning: true

  domain: 'solved'

  solve: (engine, operation, continuation, scope, ascender, ascending) ->
    return if @ == @solved
    
    for arg in operation.parent
      if arg[0] == true
        arg.shift()

    if operation.index == 1 && !ascender
      condition = engine.clone operation
      condition.parent = operation.parent
      condition.index = operation.index
      condition.domain = operation.domain
      @_solve condition, continuation, scope
      return false

  update: (engine, operation, continuation, scope, ascender, ascending) ->
    operation.parent.uid ||= '@' + (engine.methods.uid = (engine.methods.uid ||= 0) + 1)
    path = continuation + operation.parent.uid
    id = scope._gss_id
    watchers = engine.queries.watchers[id] ||= []
    if !watchers.length || engine.indexOfTriplet(watchers, operation.parent, continuation, scope) == -1
      watchers.push operation.parent, continuation, scope

    condition = ascending && (typeof ascending != 'object' || ascending.length != 0)
    if @inverted
      condition = !condition
      
    index = condition && 2 || 3
    
    old = engine.queries[path]
    if !!old != !!condition || (old == undefined && old != condition)
      d = engine.pairs.dirty
      unless old == undefined
        engine.queries.clean(engine.Continuation(path) , continuation, operation.parent, scope)
      unless engine.switching
        switching = engine.switching = true

      engine.queries[path] = condition
      if switching
        if !d && (d = engine.pairs.dirty)
          engine.pairs.onBeforeSolve()

        if engine.updating
          collections = engine.updating.collections
          engine.updating.collections = {}
          engine.updating.previous = collections

      engine.engine.console.group '%s \t\t\t\t%o\t\t\t%c%s', (condition && 'if' || 'else') + engine.Continuation.DESCEND, operation.parent[index], 'font-weight: normal; color: #999', continuation
      
      if branch = operation.parent[index]
        result = engine.document.solve(branch, engine.Continuation(path, null,  engine.Continuation.DESCEND), scope)
      if switching
        engine.pairs?.onBeforeSolve()
        engine.queries?.onBeforeSolve()
        engine.switching = undefined

      engine.console.groupEnd(path)

  # Capture commands generated by evaluation of arguments
  capture: (result, engine, operation, continuation, scope) ->
    # Condition result bubbled up, pick a branch
    if operation.index == 1
      if continuation?
        @update(engine, operation.parent[1], engine.Continuation(continuation, null, engine.Continuation.DESCEND), scope, undefined, result)
      return true
    else
    # Capture commands bubbled up from branches
      if typeof result == 'object' && !result.nodeType && !engine.isCollection(result)
        engine.provide result
        return true
      
Condition.define 'if', {}
Condition.define 'unless', {
  inverted: true
}
 
module.exports = Condition