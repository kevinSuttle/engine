# Do your math! Functions that work on fully resolved values

class Measurements

  # Add suggestions before all other commands are sent
  onFlush: (buffer) ->
    return buffer unless @engine.computed
    commands = []

    # Send all measured dimensions as suggestions to solver before other commands
    for property, value of @engine.computed
      continue if @engine.values[property] == value
      commands.push ['suggest', property, value, 'required']

    return commands.concat(buffer)

  # Math ops compatible with constraints API

  plus: (a, b) ->
    return a + b

  minus: (a, b) ->
    return a - b

  multiply: (a, b) ->
    return a * b

  divide: (a, b) ->
    return a / b


  # Global variables managed by the engine

  '::window[width]': ->
    return window.innerWidth

  '::window[height]': ->
    return window.innerHeight

  '::window[scroll-left]': ->
    return window.pageXOffset || document.documentElement.scrollLeft || document.body.scrollLeft 

  '::window[scroll-top]': ->
    return window.pageYOffset || document.documentElement.scrollTop || document.body.scrollTop 

  # Constants

  '::window[x]': 0
  '::window[y]': 0

  # Properties

  "[intrinsic-height]": (scope) ->
    return scope.offsetHeight

  "[intrinsic-width]": (scope) ->
    return scope.offsetWidth

  "[scroll-left]": (scope) ->
    return scope.scrollLeft

  "[scroll-top]": (scope) ->
    return scope.scrollTop

  "[offset-left]": (scope) ->
    return scope.offsetLeft

  "[offset-top]": (scope) ->
    return scope.offsetTop

  unwrap: (property) ->
    if property.charAt(0) == '['
      return property.substring(1, property.length - 1)
    return property

  getStyle: (element, property) ->

  setStyle: (element, property, value) ->
    element.style[@unwrap(property)] = value

  # Compute value of a property, reads the styles on elements
  compute: (id, property, continuation, old) ->
    if id.nodeType
      object = id
      id = @engine.identify(object)
    else
      object = @engine[id]

    path = property.charAt(0) == '[' && id + property || property
    if (def = @[path])?
      current = @engine.values[path]
      if current == undefined || old == true
        if typeof def == 'function'
          value = @[path](object, continuation)
        else
          value = def
        if value != current
          (@engine.computed ||= {})[path] = value
      return value
    else if property.indexOf('intrinsic-') > -1
      path = id + property
      if !@engine.computed || !@engine.computed[path]?
        if value == undefined
          method = @[property] && property || 'getStyle'
          if document.contains(object)
            value = @[method](object, property, continuation)
          else
            value = null
        if value != old
          (@engine.computed ||= {})[path] = value
    else
      return @[property](object, continuation)

  # Generate command to create a variable
  get:
    command: (continuation, object, property) ->
      debugger
      if property
        if typeof object == 'string'
          id = object

        # Get document property
        else if object.absolute is 'window' || object == document
          id = '::window'

        # Get element property
        else if object.nodeType
          id = @engine.identify(object)
      else
        # Get global variable
        id = '::global'
        property = object
        object = undefined

      if typeof continuation == 'object'
        continuation = continuation.path

      # Compute custom property
      if property.indexOf('intrinsic-') > -1 || @[property]? || @[id + property]?
        computed = @compute(id, property, continuation, true)
        if typeof computed == 'object'
          return computed

      # Return command for solver with path which will be used to clean it
      return ['get', id, property, continuation || '']

  _export: (object) ->
    for property, def of @
      continue if object[property]?
      if property == 'unwrap'
        object[property] = def
        continue
      do (def, property) ->
        if typeof def == 'function'
          func = def
        measurements = Measurements::

        object[property] = (scope) ->
          args = Array.prototype.slice.call(arguments, 0)
          length = arguments.length
          if def.serialized || measurements[property]
            unless scope && scope.nodeType
              scope = object.scope || document.body
              if typeof def[args.length] == 'string'
                context = scope
              else
                args.unshift(scope)
            else
              if typeof def[args.length - 1] == 'string'
                context = scope = args.shift()

          unless fn = func
            if typeof (method = def[args.length]) == 'function'
              fn = method
            else
              unless method && (fn = scope[method])
                if fn = scope[def.method]
                  context = scope
                else
                  fn = def.command

          return fn.apply(context || object.context || @, args)


module.exports = Measurements