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
  ###
  unless templ.html?
    templ = DB.Template.findOne templ, fields:
      name: 1
      html: 1
      css: 1
      scripts: 1
      version: 1
  ###
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
    console.log 'Error compiling', res._id, 'template:', res
    console.log err
    return
    # TODO: report error

  ###
  Template[name].onRendered ->
    Session.set 'is loading', false
    Session.set 'is errored', false
  Template[name].onDestroyed ->
    Session.set 'is loading', true
  ###

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
      inner = eval(js).apply(window.scriptHelpers)
    catch err
      console.log "Couldn't compile", key, "for", name, '-', err
      return

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
        Template[name].events { "#{param}": func }

      when 'hook'
        Template[name].registerHook param, func

      when 'on-create'
        Template[name].onCreated func

      when 'on-render'
        Template[name].onRendered func

      when 'on-destroy'
        Template[name].onDestroyed func


  ### Context hooks
  Template[name].onCreated ->
    @autorun =>
      # The context hook should return an object with any of these keys:
      #   title - What this display should be visually labeled
      #   icon - URL to image to show in the header
      #   color - Background color behind the content
      Session.set 'display-context', @hook('context') ? {}
  Template[name].onDestroyed ->
    Session.set 'display-context', {}
  ###

  Template[name].baseName = res.name
  Template[name].dynName = name
  return Template[name]
