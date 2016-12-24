Template.registerHelper 'eq',
  (a, b) -> a is b

Template.registerHelper 'renderTemplate', ->
  packageId = Session.get 'app id'
  if template = DB.Template.findOne({@name, packageId})
    name = compileTemplate template._id
    return Template[name]
  null
