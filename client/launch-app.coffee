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

getAppFromPath = ->
  if location.pathname is '/'
    return 'build-launch'

  if firstPart = location.pathname.split('/')[1]
    if firstPart[0] is '~'
      return firstPart.slice(1)

global.SUBDOMAIN_APPS = false
if global.APP_ID = getAppFromHost()
  global.SUBDOMAIN_APPS = true
else if global.APP_ID = getAppFromPath()
  global.SUBDOMAIN_APPS = false

console.log 'Detected app from URL:', APP_ID

# TODO: subscribe to either entire app or system-wide config
if APP_ID
  global.SUBSCRIPTION = Meteor.subscribe '/app-runtime', APP_ID
#else
#  global.SUBSCRIPTION = Meteor.subscribe '/management'

# Allow <a href=...> tags in apps to do the right thing
Template.body.helpers
  currentApp: ->
    DB.App.findOne APP_ID
  appBase: ->
    if SUBDOMAIN_APPS then '/'
    else "/~#{APP_ID}/"


launchApp = (appId) ->
  # Get the app straight, first
  app = DB.App.findOne appId
  return false unless app

  # Fetch the app's global routing table
  routeTable = DB.RouteTable.findOne
    packageId: appId
    name: 'RootRoutes' # TODO?
  return unless routeTable
  routeTable.entries.forEach (r) ->
    r.url = new Iron.Url r.path

  # Apply app-wide layout if any
  try if routeTable.layout
    @layout DUST.get(routeTable.layout, 'Template').dynName
  catch err
    console.log "Temp failed to load layout #{routeTable.layout}"
    @render 'LoadingDustCrash'
    return true

  # Find the first matching route
  {path, query} = @params
  path ||= '/home'
  route = routeTable.entries.find (r) -> r.url.test(path)
  unless route
    console.log 'No app route matched', path
    alert 'Routing 404!'
    return false
    # TODO: 404

  # Build params mapping
  match = route.url.exec(path)
  params = JSON.parse JSON.stringify query # TODO
  route.url.keys.forEach (param, idx) ->
    params[param.name] = match[idx + 1]

  # Context for route actions to leverage
  DUST.params.set params
  ctx =
    params: params

    # Compiles requested template then actually renders
    render: (templateName, opts={}) =>
      template = DUST.get (templateName ? route.Name), 'Template'
      opts.data ?= {params}
      DUST._mainTemplate = template.baseName
      @render template.dynName, opts

  # Perform the actual action
  try switch route.type
    when 'template'
      ctx.render route.template, route.params

    when 'customAction'
      # Compile the route action
      inner = eval(route.customAction.js).apply(window.scriptHelpers)
      inner.apply(ctx)

    else throw new Meteor.Error 'unknown-route',
      "This route type #{route.type} is not implemented"

  catch err
    console.log "Couldn't run '#{route.type}' route action for #{route.url}"
    @render 'LoadingDustCrash'
    return true
  true

Router.route '/', ->
  return if launchApp.call @, 'build-launch'
  @render 'LoadingDust'

if SUBDOMAIN_APPS
  # https://the-app.the-platform/blah
  # DANGER: this route will eat any 404
  # TODO: 404 if the app doesn't have the route
  Router.route '/:path(.*)', ->
    return if launchApp.call @, APP_ID
    @render 'LoadingDust'

else if APP_ID
  # https://the-platform/~the-app/blah
  # Let the client reload when switching apps
  Router.route "/~#{APP_ID}/:path(.*)", ->
    return if launchApp.call @, APP_ID
    @render 'LoadingDust'

if APP_ID
  Tracker.autorun ->
    app = DB.App.findOne(APP_ID)

  # Wait for the application to download, then attempt auto-sub
  Tracker.autorun -> if SUBSCRIPTION.ready()
    if DB.Publication.find(name: 'Default', packageId: APP_ID).count()
      DUST.get('Default', 'Publication').subscribe()
