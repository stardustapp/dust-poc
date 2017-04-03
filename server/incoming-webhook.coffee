Router.route '/webhook/~:appId/:methName',
  where: 'server'
.post ->
  {appId, methName} = @params
  {query, body} = @request

  injector = getInjector appId
  method = injector.getSource methName, 'ServerMethod'

  scriptHelpers =
    get: (name, type) ->
      injector.get(name, type)

  # TODO: THIS IS VERY FUCKING INSECURE
  # TODO: PLEASE FIGURE OUT SANDBOXING ON THE SERVER
  # TODO: VERY BAD THINGS CAN HAPPEN OTHERWISE

  try
    inner = eval(method.js).apply(scriptHelpers)
  catch err
    console.log "Couldn't compile", appId, "method", method.name, '-', err
    throw new Meteor.Error 'script-error',
      "Couldn't compile method. #{err.name} #{err.message}"

  try
    func = inner.apply body, query
    obj = func.apply body, query
    console.log 'Returned', obj
    this.response.end JSON.stringify(obj)

  catch err
    stack = err.stack.split('[object Object].eval')[0]
    [_, lineNum, charNum] = err.stack.match(/<anonymous>:(\d+):(\d+)/) ? []
    if lineNum?
      stack += "#{methName} (#{lineNum}:#{charNum} for app #{appId})"
      console.log stack

      line = method.js.split('\n')[lineNum-1]
      console.log 'Responsible line:', line.trim()
    else
      console.log err

    throw new Meteor.Error 'script-error',
      "Couldn't execute webhook. #{err.name} #{err.message}"
