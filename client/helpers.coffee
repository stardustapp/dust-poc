Template.registerHelper 'eq',
  (a, b) -> a is b

Template.registerHelper 'renderTemplate', ->
  packageId = APP_ID
  if template = DB.Template.findOne({@name, packageId})
    name = compileTemplate template._id
    return Template[name]
  null
