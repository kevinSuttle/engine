### Selectors with custom combinators 
inspired by Slick of mootools fame (shout-out & credits)

Combinators fetch new elements, while qualifiers filter them.

###

Command = require('../concepts/Command')
Query   = require('./Query')

class Selector extends Query
  prepare: (operation, parent) ->
    prefix = ((parent && operation.name != ' ') || 
          (operation[0] != '$combinator' && typeof operation[1] != 'object')) && 
          ' ' || ''
    switch operation[0]
      when '$tag'
        if (!parent || operation == operation.selector?.tail) && operation[1][0] != '$combinator'
          tags = ' '
          index = (operation[2] || operation[1]).toUpperCase()
      when '$combinator'
        tags = prefix + operation.name
        index = operation.parent.name == "$tag" && operation.parent[2].toUpperCase() || "*"
      when '$class', '$pseudo', '$attribute', '$id'
        tags = prefix + operation[0]
        index = (operation[2] || operation[1])
    return unless tags
    ((@[tags] ||= {})[index] ||= []).push operation

    
  # String to be used to join tokens in a list
  separator: ''
  # Does selector start with ::this?
  scoped: undefined

  # Redefined function name for serialized key
  prefix: undefined
  # Trailing string for a serialized key
  suffix: undefined

  # String representation of current selector operation
  key: undefined
  # String representation of current selector operation chain
  path: undefined

  # Reference to first operation in tags
  tail: undefined
  # Reference to last operation in tags
  head: undefined

  # Does the selector return only one element?
  singular: undefined
  # Is it a "free" selector like ::this or ::scope?
  hidden: undefined
  
  
  relative: undefined

      
    
  # Check if query was already updated
  before: (node, args, engine, operation, continuation, scope) ->
    unless @hidden
      return engine.queries.fetch(node, args, operation, continuation, scope)

  # Subscribe elements to query 
  after: (node, args, result, engine, operation, continuation, scope) ->
    unless @hidden
      return engine.queries.update(node, args, result, operation, continuation, scope)


Query::mergers.selector = (command, other, parent, operation, inherited) ->
  if !other.head
    # Native selectors cant start with combinator other than whitespace
    if other instanceof Query.Combinator && operation[0] != ' '
      return

  # Can't append combinator to qualifying selector selector 
  if selecting = command instanceof Query.Selecter
    return unless other.selecting
  else if other.selecting
    command.selecting = true

  other.head = parent
  command.head = parent
  command.tail = other.tail || operation
  command.tail.head = parent
  right = command.selector || command.key
  if inherited
    command.selector = (command.selector || command.key) + command.separator + (other.selector || other.key)
  else
    command.selector = (other.selector || other.key) + (command.selector || command.key)
  return true

# Indexed collection
class Query.Selecter extends Selector
  signature: [
    query: ['String']
  ]

# Scoped indexed collections
class Query.Combinator extends Query.Selecter
  signature: [[
    context: ['Query']
    query: ['String']
  ]]

# Filter elements by key
class Query.Qualifier extends Selector
  signature: [
    context: ['Query']
    matcher: ['String']
  ]

# Filter elements by key with value
class Query.Search extends Selector
  signature: [
    context: ['Query']
    matcher: ['String']
    query: ['String']
  ]
  
# Reference to related element
class Query.Element extends Selector
  signature: []
  
Query.define
  # Live collections

  'class':
    prefix: '.'
    tags: ['selector']
    
    Selecter: (value, engine, operation, continuation, scope) ->
      return (scope || @scope).getElementsByClassName(value)
      
    Qualifier: (node, value) ->
      return node if node.classList.contains(value)

  'tag':
    tags: ['selector']
    prefix: ''

    Selecter: (value, engine, operation, continuation, scope) ->
      return (scope || @scope).getElementsByTagName(value)
    
    Qualifier: (node, value) ->
      return node if value == '*' || node.tagName == value.toUpperCase()

  # DOM Lookups

  'id':
    prefix: '#'
    tags: ['selector']
    
    Selecter: (id, engine, operation, continuation, scope = @scope) ->
      return scope.getElementById?(id) || node.querySelector('[id="' + id + '"]')
      
    Qualifier: (node, value) ->
      return node if node.id == value


  # All descendant elements
  ' ':
    tags: ['selector']
    
    Combinator: (node) ->
      return node.getElementsByTagName("*")

  # All parent elements
  '!':
    Combinator: (node) ->
      nodes = undefined
      while node = node.parentNode
        if node.nodeType == 1
          (nodes ||= []).push(node)
      return nodes

  # All children elements
  '>':
    tags: ['selector']
    Combinator: (node) -> 
      return node.children

  # Parent element
  '!>':
    Combinator: (node) ->
      return node.parentElement

  # Next element
  '+':
    tags: ['selector']
    Combinator: (node) ->
      return node.nextElementSibling

  # Previous element
  '!+':
    Combinator: (node) ->
      return node.previousElementSibling

  # All direct sibling elements
  '++':
    Combinator: (node) ->
      nodes = undefined
      if prev = node.previousElementSibling
        (nodes ||= []).push(prev)
      if next = node.nextElementSibling
        (nodes ||= []).push(next)
      return nodes

  # All succeeding sibling elements
  '~':
    tags: ['selector']
    Combinator: (node) ->
      nodes = undefined
      while node = node.nextElementSibling
        (nodes ||= []).push(node)
      return nodes

  # All preceeding sibling elements
  '!~':
    Combinator: (node) ->
      nodes = undefined
      prev = node.parentNode.firstElementChild
      while prev != node
        (nodes ||= []).push(prev)
        prev = prev.nextElementSibling
      return nodes

  # All sibling elements
  '~~':
    Combinator: (node) ->
      nodes = undefined
      prev = node.parentNode.firstElementChild
      while prev
        if prev != node
          (nodes ||= []).push(prev) 
        prev = prev.nextElementSibling
      return nodes


Query.define
  # Pseudo elements
  '::this':
    hidden: true
    mark: 'ASCEND'
    Element: (engine, operation, continuation, scope) ->
      return scope

  # Parent element (alias for !> *)
  '::parent':
    Element: Query['!>']::Combinator

  # Current engine scope (defaults to document)
  '::scope':
    hidden: true
    Element: (engine, operation, continuation, scope) ->
      return engine.scope

  # Return abstract reference to window
  '::window':
    hidden: true
    Element: ->
      return '::window' 
  

Query.define  
  '[=]':
    tags: ['selector']
    prefix: '['
    separator: '="'
    suffix: '"]'
    Search: (node, attribute, value) ->
      return node if node.getAttribute(attribute) == value

  '[*=]':
    tags: ['selector']
    prefix: '['
    separator: '*="'
    suffix: '"]'
    Search: (node, attribute, value) ->
      return node if node.getAttribute(attribute)?.indexOf(value) > -1

  '[|=]':
    tags: ['selector']
    prefix: '['
    separator: '|="'
    suffix: '"]'
    Search: (node, attribute, value) ->
      return node if node.getAttribute(attribute)?

  '[]':
    tags: ['selector']
    prefix: '['
    suffix: ']'
    Search: (node, attribute) ->
      return node if node.getAttribute(attribute)?



# Pseudo classes

Query.define
  ':value':
    Qualifier: (node) ->
      return node.value
    watch: "oninput"

  ':get':
    Combinator: (property, engine, operation, continuation, scope) ->
      return scope[property]

  ':first-child':
    tags: ['selector']
    Combinator: (node) ->
      return node unless node.previousElementSibling

  ':last-child':
    tags: ['selector']
    Combinator: (node) ->
      return node unless node.nextElementSibling


  ':next':
    relative: true
    Combinator: (node, engine, operation, continuation, scope) ->
      collection = engine.queries.getScopedCollection(operation, continuation, scope)
      index = collection?.indexOf(node)
      return if !index? || index == -1 || index == collection.length - 1
      return collection[index + 1]

  ':previous':
    relative: true
    Combinator: (node, engine, operation, continuation, scope) ->
      collection = engine.queries.getScopedCollection(operation, continuation, scope)
      index = collection?.indexOf(node)
      return if index == -1 || !index
      return collection[index - 1]

  ':last':
    relative: true
    singular: true
    Combinator: (node, engine, operation, continuation, scope) ->
      collection = engine.queries.getScopedCollection(operation, continuation, scope)
      index = collection?.indexOf(node)
      return if !index?
      return node if index == collection.length - 1

  ':first':
    relative: true
    singular: true
    Qualifier: (node, engine, operation, continuation, scope) ->
      collection = engine.queries.getScopedCollection(operation, continuation, scope)
      index = collection?.indexOf(node)
      return if !index?
      return node if index == 0
  
  # Comma combines results of multiple selectors without duplicates
  ',':
    # If all sub-selectors are selector, make a single comma separated selector
    tags: ['selector']

    # Dont let undefined arguments stop execution
    eager: true

    signature: null,
    separator: ','

    # Comma only serializes arguments
    toString: ->
      return ''

    # Return deduplicated collection of all found elements
    command: (engine, operation, continuation, scope) ->
      contd = @Continuation.getScopePath(scope, continuation) + operation.path
      if @queries.ascending
        index = @engine.indexOfTriplet(@queries.ascending, operation, contd, scope) == -1
        if index > -1
          @queries.ascending.splice(index, 3)

      return @queries[contd]

    # Recieve a single element found by one of sub-selectors
    # Duplicates are stored separately, they dont trigger callbacks
    capture: (result, engine, operation, continuation, scope, ascender) ->
      contd = engine.Continuation.getScopePath(scope, continuation) + operation.parent.path
      engine.queries.add(result, contd, operation.parent, scope, operation, continuation)
      engine.queries.ascending ||= []
      if engine.indexOfTriplet(engine.queries.ascending, operation.parent, contd, scope) == -1
        engine.queries.ascending.push(operation.parent, contd, scope)
      return true

    # Remove a single element that was found by sub-selector
    # Doesnt trigger callbacks if it was also found by other selector
    release: (result, engine, operation, continuation, scope) ->
      contd = engine.Continuation.getScopePath(scope, continuation) + operation.parent.path
      engine.queries.remove(result, contd, operation.parent, scope, operation, undefined, continuation)
      return true

if document?
  # Add shims for IE<=8 that dont support some DOM properties
  dummy = Selector.dummy = document.createElement('_')

  unless dummy.hasOwnProperty("classList")
    Query['class']::Qualifier = (node, value) ->
      return node if node.className.split(/\s+/).indexOf(value) > -1
      
  unless dummy.hasOwnProperty("parentElement") 
    Query['!>']::Combinator = Selector['::parent']::Element = (node) ->
      if parent = node.parentNode
        return parent if parent.nodeType == 1
  unless dummy.hasOwnProperty("nextElementSibling")
    Query['+']::Combinator = (node) ->
      while node = node.nextSibling
        return node if node.nodeType == 1
    Query['!+']::Combinator = (node) ->
      while node = node.previousSibling
        return node if node.nodeType == 1
    Query['++']::Combinator = (node) ->
      nodes = undefined
      prev = next = node
      while prev = prev.previousSibling
        if prev.nodeType == 1
          (nodes ||= []).push(prev)
          break
      while next = next.nextSibling
        if next.nodeType == 1
          (nodes ||= []).push(next)
          break
      return nodes
    Query['~']::Combinator = (node) ->
      nodes = undefined
      while node = node.nextSibling
        (nodes ||= []).push(node) if node.nodeType == 1
      return nodes
    Query['!~']::Combinator = (node) ->
      nodes = undefined
      prev = node.parentNode.firstChild
      while prev && (prev != node)
        (nodes ||= []).push(prev) if prev.nodeType == 1
        prev = prev.nextSibling
      return nodes
    Query['~~']::Combinator = (node) ->
      nodes = undefined
      prev = node.parentNode.firstChild
      while prev
        if prev != node && prev.nodeType == 1
          (nodes ||= []).push(prev) 
        prev = prev.nextSibling
      return nodes
    Query[':first-child']::Qualifier = (node) ->
      if parent = node.parentNode
        child = parent.firstChild
        while child && child.nodeType != 1
          child = child.nextSibling
        return node if child == node
    Query[':last-child']::Qualifier = (node) ->
      if parent = node.parentNode
        child = parent.lastChild
        while child && child.nodeType != 1
          child = child.previousSibling
        return mpde if child == node

module.exports = Selector