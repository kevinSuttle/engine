# Queue and group expressions by domain

Workflow = (domain, problem, frame) ->
  if @ instanceof Workflow
    @domains  = domain  && (domain.push && domain  || [domain] ) || []
    @problems = problem && (domain.push && problem || [problem]) || []
    @frame    = frame
    return
  if arguments.length == 1
    problem = domain
    domain = undefined
    start = true
  for arg, index in problem
    continue unless arg?.push
    arg.parent ?= problem
    arg.index  ?= index
    offset = 0
    if arg[0] == 'get'
      vardomain = @getVariableDomain(arg)
      if vardomain.MAYBE && domain && domain != true
        vardomain.frame = domain
      workload = new Workflow vardomain, [arg]
    else
      for a in arg
        if a?.push
          if arg[0] == 'framed'
            if typeof arg[1] == 'string'
              d = arg[1]
            else
              d = arg[0].uid ||= (@uids = (@uids ||= 0) + 1)
          else
            d = domain || true
          workload = @Workflow(d, arg)
          break

    if workflow && workflow != workload
      workflow.merge(workload)
    else
      workflow = workload
  if !workflow
    if typeof arg[0] == 'string'
      arg = [arg]
    foreign = true
    d = 
    workflow = new @Workflow [domain != true && domain || null], [arg]
  if typeof problem[0] == 'string'
    workflow.wrap(problem, @)
  if start || foreign
    if @workflow
      console.info(JSON.stringify(problem))
      return @workflow.merge(workflow)
    else
      return workflow.each @resolve, @engine

  return workflow

Workflow.prototype =
  provide: (solution) ->
    return if solution.operation.exported
    operation = solution.domain.getRootOperation(solution.operation.parent)
    domain = operation.domain
    index = @domains.indexOf(domain)
    if index == -1
      index += @domains.push(domain)
    if problems = @problems[index]
      if problems.indexOf(operation) == -1
        problems.push operation
    else
      @problems[index] = [operation]
    return

  # Group expressions
  wrap: (problem, engine) -> 
    bubbled = undefined
    for other, index in @domains by -1
      exps = @problems[index]
      i = 0
      while exp = exps[i++]
        # If this domain contains argument of given expression
        continue unless  (j = problem.indexOf(exp)) > -1

        # Replace last argument of the strongest domain 
        # with the given expression (bubbles up domain info)
        k = l = j
        while (next = problem[++k]) != undefined
          if next && next.push
            break
        continue if next
        while (previous = problem[--l]) != undefined
          if previous && previous.push && exps.indexOf(previous) == -1
            for domain, n in @domains by -1
              continue if n == index 
              probs = @problems[n]
              if (j = probs.indexOf(previous)) > -1
                if domain != other && domain.priority < 0 && other.priority < 0
                  if !domain.MAYBE
                    if !other.MAYBE
                      debugger
                      if index < n
                        exps.push.apply(exps, domain.export())
                        exps.push.apply(exps, probs)
                        @domains.splice(n, 1)
                        @problems.splice(n, 1)
                        engine.domains.splice engine.domains.indexOf(domain), 1
                      else
                        probs.push.apply(probs, other.export())
                        probs.push.apply(probs, exps)
                        @domains.splice(index, 1)
                        @problems.splice(index, 1)
                        engine.domains.splice engine.domains.indexOf(other), 1
                        other = domain
                    break
                  else if !other.MAYBE
                    @problems[i].push.apply(@problems[i], @problems[n])
                    @domains.splice(n, 1)
                    @problems.splice(n, 1)
                    continue
                if domain.priority < 0 && (domain.priority > other.priority || other.priority > 0)
                  i = j + 1
                  exps = @problems[n]
                  other = domain
                break
            break

        #console.log('grouping', problem, exp, problem == exp)
        opdomain = engine.getOperationDomain(problem, other)
        if opdomain && opdomain != other
          if (index = @domains.indexOf(opdomain)) == -1
            index = @domains.push(opdomain) - 1
            @problems[index] = [problem]
          else
            @problems[index].push problem
          strong = undefined
          for arg in exp
            if arg.domain && !arg.domain.MAYBE
              strong = true
          unless strong
            exps.splice(--i, 1)

          other = opdomain
          console.error(opdomain, '->', other, problem)
        else unless bubbled
          bubbled = true
          exps[i - 1] = problem
        for domain, counter in @domains
          if domain.displayName == other.displayName
            problems = @problems[counter]
            for arg in problem
              if (j = problems.indexOf(arg)) > -1
                problems.splice(j, 1)

        @setVariables(problem, engine)
        return true

  # Simplify groupped multi-domain expression down to variables
  unwrap: (problems, domain, result = []) ->
    if problems[0] == 'get'
      problems.exported = true
      result.push(problems)
    else
      problems.domain = domain
      for problem in problems
        if problem.push
          @unwrap(problem, domain, result)
    return result

  setVariables: (problem, engine, target = problem) ->
    for arg in problem
      if arg[0] == 'get'
        (target.variables ||= []).push(engine.getPath(arg[1], arg[2]))
      else if arg.variables
        (target.variables ||= []).push.apply(target.variables, arg.variables)

  # Last minute changes to workflow before execution
  optimize: ->
    console.log(JSON.stringify(@problems))
    # Remove empty domains
    for problems, i in @problems by -1
      unless problems.length
        @problems.splice i, 1
        @domains.splice i, 1
      for problem in problems
        problem.domain = @domains[i]

    # Merge connected graphs 
    for domain, i in @domains by -1
      problems = @problems[i]
      @setVariables(problems)
      if vars = problems.variables
        for other, j in @domains by -1
          break if j == i
          if (variables = @problems[j].variables) && domain.displayName == @domains[j].displayName
            if domain.frame == other.frame
              for variable in variables
                if vars.indexOf(variable) > -1
                  problems.push.apply(problems, @problems[j])
                  @setVariables(@problems[j], null, problems)
                  @problems.splice(j, 1)
                  @domains.splice(j, 1)
                  break

    # Defer substitutions to thread
    for domain, i in @domains by -1
      for j in [i + 1 ... @domains.length]
        if (url = @domains[j]?.url) && document?
          for prob, p in @problems[i] by -1
            while prob
              problem = @problems[j]
              if problem.indexOf(prob) > -1

                @problems[i][p] = @unwrap @problems[i][p], @domains[j], [], @problems[j]
                break
              prob = prob.parent

    # Remove empty domains
    for problems, i in @problems by -1
      unless problems.length
        @problems.splice i, 1
        @domains.splice i, 1
      for problem in problems by -1
        domain = @domains[i]
        problem.domain = domain



    @



  # Merge source workflow into target workflow
  merge: (problems, domain) ->
    if domain == undefined
      for domain, index in problems.domains
        @merge problems.problems[index], domain
      return @
    merged = undefined
    priority = @domains.length
    position = (@index || -1) + 1
    while (other = @domains[position]) != undefined
      if other
        if other == domain
          cmds = @problems[position]
          cmds.push.apply(cmds, problems)
          merged = true
          break
        else 
          if other.priority <= domain.priority && (!other.frame || other.frame == domain.frame)
            priority = position
      position++
    if !merged
      @domains.splice(priority, 0, domain)
      @problems.splice(priority, 0, problems)

    return @

  each: (callback, bind) ->
    @optimize()
    solution = undefined
    @index ?= 0
    while (domain = @domains[@index]) != undefined
      result = (@solutions ||= [])[@index] = 
        callback.call(bind || @, domain, @problems[@index], @index, @)
      if result && !result.push
        for own prop, value of result
          (solution ||= {})[prop] = value
      @index++

    return solution || result

module.exports = Workflow