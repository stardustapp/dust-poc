Template.body.helpers
  currentApp: ->
    DB.App.findOne Session.get 'app id'

Router.route '/~:appId/:path(.*)', ->
  # Get the app straight, first
  {appId, path} = @params
  app = DB.App.findOne appId
  return unless app
  Session.set 'app id', app._id

  # Apply app-wide layout if any
  if app.layoutId
    @layout compileTemplate(app.layoutId)

  # Fetch the app's routing table
  routes = DB.Route.find(packageId: appId).fetch()
  routes.forEach (r) ->
    r.url = new Iron.Url r.path

  # Find the first matching route
  route = routes.find (r) -> r.url.test(path)
  return unless route
  # TODO: 404

  # Build params mapping
  match = route.url.exec(path)
  params = {}
  route.url.keys.forEach (param, idx) ->
    params[param.name] = match[idx + 1]

  # Compile the route action
  try
    inner = eval(route.actionJs).apply(window.scriptHelpers)
  catch err
    console.log "Couldn't compile route", route, '-', err
    return
    # TODO: 500

  # Invoke the route action with context
  ctx =
    params: params

    # Compiles requested template then actually renders
    render: (templateName, opts={}) =>
      template = DB.Template.findOne
        packageId: appId
        name: templateName ? route.Name
      # TODO: 500

      opts.data ?= {params}
      @render compileTemplate(template._id), opts

  inner.apply(ctx)
