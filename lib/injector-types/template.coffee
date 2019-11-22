# Call a hook on an instance
Blaze?.TemplateInstance.prototype.hook = (key, args...) ->
  check key, String
  {hooks} = @view.template
  hooks[key]?.apply @, args

# Register hooks on a template
Blaze?.Template.prototype.registerHook = (key, hook) ->
  if key of @hooks
    throw new Meteor.Error 'hook-exists', "Template hook already exists"
  @hooks[key] = hook

InjectorTypes.set 'Template', (res) ->
  return unless res?.html
  name = ['Tmpl', res._id, res.version].join '_'

  # We have versioning, that lets us reuse
  if name of Template
    return Template[name]

  parts = [res.html]
  if res.css
    parts.push "<style type='text/css'>#{res.css}</style>"

  source = parts.join '\n\n'
  try
    compiled = SpacebarsCompiler.compile source,
      isTemplate: true

    # Little monkeypatching never hurt anyone
    compiled = compiled.replace /HTML\.getTag\("/g,
      'HTML.getSmartTag(view, "'

    renderer = eval(compiled)
    UI.Template.__define__ name, renderer
  catch err
    delete Template[name]
    console.log 'Error compiling', res._id, 'template:', res
    # TODO: report error
    if window.localStorage.SloppyDust
      console.log 'Full template compile error:', err
    else
      throw err

  # register template for outside hooking
  unless DUST._liveTemplates.has res.name
    DUST._liveTemplates.set res.name,
      dep: new Tracker.Dependency()
      instances: new Set()
  liveSet = DUST._liveTemplates.get res.name

  # init hook system
  Template[name].hooks = {}
  Template[name].onCreated ->
    liveSet.instances.add @
    liveSet.dep.changed()
  Template[name].onDestroyed ->
    liveSet.instances.delete @
    liveSet.dep.changed()

  Template[name].injector = @

  res.scripts.forEach ({key, type, param, js}) ->
    try
      raw = eval(js)
      unless js.endsWith '.call();\n'
        raw = raw.apply(window.scriptHelpers)
      inner = raw.apply() # .apply(window.scriptHelpers) # TODO: used?
    catch err
      delete Template[name]
      console.log "Couldn't compile", key, "for", name, '-', err.error
      # TODO: report error
      if window.localStorage.SloppyDust
        console.log 'Full script compile error:', err
      else
        throw err

    func = -> try
      inner.apply(@, arguments)
    catch err
      stack = err.stack?.split('Object.eval')[0]
      [_, lineNum, charNum] = err.stack?.match(/<anonymous>:(\d+):(\d+)/) ? []
      if lineNum?
        stack += "#{key} (#{lineNum}:#{charNum} for view #{res._id})"
        console.log err.message, stack

        line = js.split('\n')[lineNum-1]
        console.log 'Responsible line:', line
      else
        console.log err

      # TODO: report error

    switch DB.TemplateScriptType.getIdentifier(type)
      when 'helper'
        Template[name].helpers { "#{param}": func }

      when 'event'
        # rewrite stuff like [href=#asdf] for stricter parser
        if match = param.match(/^([^ ]+) \[([^=]+)=([^"].+[^"])\]$/)
          [_, evt, attr, val] = match
          Template[name].events { "#{evt} [#{attr}=\"#{val}\"]": func }
        else
          Template[name].events { "#{param}": func }

      when 'hook'
        Template[name].registerHook param, func

      when 'on-create'
        Template[name].onCreated func

      when 'on-render'
        Template[name].onRendered func

      when 'on-destroy'
        Template[name].onDestroyed func

  Template[name].baseName = res.name
  Template[name].dynName = name
  return Template[name]
