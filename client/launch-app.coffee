# Detect appId from hostname
getAppFromHost = ->
  baseHost = Meteor.absoluteUrl().split('/')[2]
  fullHost = location.host

  # Make sure we're APPID.the-platform.com format
  baseIdx = fullHost.length - baseHost.length
  return unless baseIdx > 1
  return unless fullHost.lastIndexOf(baseHost) is baseIdx

  appId = fullHost.slice 0, baseIdx-1
  return if '.' in appId
  appId

root.APP_ID = getAppFromHost()
console.log 'Detected app from hostname:', APP_ID

# TODO: subscribe to either entire app or system-wide config
if APP_ID
  root.SUBSCRIPTION = Meteor.subscribe '/app-runtime', APP_ID
else
  root.SUBSCRIPTION = Meteor.subscribe '/management'

# Allow <a href=...> tags in apps to do the right thing
Template.body.helpers
  currentApp: ->
    DB.App.findOne Session.get 'app id'
  appBase: ->
    if APP_ID then '/'
    else "/~#{@_id}/"


launchApp = (appId) ->
  # Get the app straight, first
  app = DB.App.findOne appId
  return unless app
  Session.set 'app id', app._id

  # Fetch the app's root routing table
  routeTable = DB.RouteTable.findOne
    packageId: appId
    name: 'RootRoutes' # TODO?
  routeTable.entries.forEach (r) ->
    r.url = new Iron.Url r.path

  # Apply app-wide layout if any
  if routeTable.layout
    template = DB.Template.findOne
      packageId: appId
      name: routeTable.layout

    # Make sure the layout is actually known
    if template._id
      @layout compileTemplate(template._id)
    else
      # TODO: 500

  # Find the first matching route
  {path} = @params
  path ||= '/home'
  route = routeTable.entries.find (r) -> r.url.test(path)
  unless route
    console.log 'No app route matched', path
    alert 'Routing 404!'
    return
    # TODO: 404

  # Build params mapping
  match = route.url.exec(path)
  params = {}
  route.url.keys.forEach (param, idx) ->
    params[param.name] = match[idx + 1]

  # Context for route actions to leverage
  DUST.params.set params
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

  # Perform the actual action
  switch route.type
    when 'template'
      ctx.render route.template, route.params

    when 'customAction'
      # Compile the route action
      try
        inner = eval(route.customAction.js).apply(window.scriptHelpers)
      catch err
        console.log "Couldn't compile custom code for route", route, '-', err
        return
        # TODO: 500

      inner.apply(ctx)

if APP_ID
  # https://the-app.the-platform/blah
  # DANGER: this route will eat any 404
  # TODO: 404 if the app doesn't have the route
  Router.route '/:path(.*)', ->
    launchApp.call @, APP_ID

else
  # https://the-platform/~the-app/blah
  Router.route '/~:appId/:path(.*)', ->
    launchApp.call @, @params.appId
