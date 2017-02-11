# Call a hook on an instance
Blaze.TemplateInstance.prototype.hook = (key, args...) ->
  check key, String
  {hooks} = @view.template
  hooks[key]?.apply @, args

# Register hooks on a template
Blaze.Template.prototype.registerHook = (key, hook) ->
  if key of @hooks
    throw new Meteor.Error 'hook-exists', "Template hook already exists"
  @hooks[key] = hook

# Coffeescript now wraps random things like so:
# thing = module.runModuleSetters(eval(compiled))
# Seems related to ES6. Just bypass for now.
window.module =
  runModuleSetters: (x) -> x

window.compileTemplate = (templ) ->
  unless templ.html?
    templ = DB.Template.findOne templ, fields:
      name: 1
      html: 1
      css: 1
      scripts: 1
      version: 1
  return unless templ?.html
  name = ['Tmpl', templ._id, templ.version].join '_'

  # We have versioning, that lets us reuse
  if name of Template
    return name

  parts = [templ.html]
  if templ.css
    parts.push "<style type='text/css'>#{templ.css}</style>"

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
    console.log 'Error compiling', templ._id, 'template:', templ
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
  unless DUST._liveTemplates.has templ.name
    DUST._liveTemplates.set templ.name,
      dep: new Tracker.Dependency()
      instances: new Set()
  liveSet = DUST._liveTemplates.get templ.name

  # init hook system
  Template[name].hooks = {}
  Template[name].onCreated ->
    liveSet.instances.add @
    liveSet.dep.changed()
  Template[name].onDestroyed ->
    liveSet.instances.delete @
    liveSet.dep.changed()

  templ.scripts.forEach ({key, type, param, js}) ->
    try
      inner = eval(js).apply(window.scriptHelpers)
    catch err
      console.log "Couldn't compile", key, "for", name, '-', err
      return

    func = -> try
      inner.apply(@, arguments)
    catch err
      stack = err.stack.split('Object.eval')[0]
      [_, lineNum, charNum] = err.stack.match(/<anonymous>:(\d+):(\d+)/) ? []
      if lineNum?
        stack += "#{key} (#{lineNum}:#{charNum} for view #{templ._id})"
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

  Template[name].baseName = templ.name
  Template[name].dynName = name
  return name
