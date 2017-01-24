Template.registerHelper 'eq',
  (a, b) -> a is b

Template.registerHelper 'renderTemplate', ->
  try
    DUST.get(@name, 'Template')
  catch err
    console.log "Failed to render template", @name, err.message
    return null
