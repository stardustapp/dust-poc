Template.body.helpers
  currentApp: ->
    DB.App.findOne Session.get 'app id'

Router.route '/~:appId/:path(.*)', ->
  {appId, path} = @params
  app = DB.App.findOne appId
  return unless app
  Session.set 'app id', app._id

  # TODO
  routes = [
    { path: '/home', templateName: 'Home' }
  ]
  routes.forEach (r) ->
    r.url = new Iron.Url r.path


  if app.layoutId
    @layout compileTemplate(app.layoutId)

  route = routes.find (r) -> r.url.test(path)
  # TODO: 404

  match = route.url.exec(path)
  template = DB.Template.findOne
    packageId: appId
    name: route.templateName
  # TODO: 500

  params = {}
  route.url.keys.forEach (param, idx) ->
    params[param.name] = match[idx + 1]

  @render compileTemplate(template._id),
    data: -> {params}
