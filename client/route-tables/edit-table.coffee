Router.route '/~~/packages/:packageId/route-tables/new', ->
  rt = new DB.RouteTable
    packageId: @params.packageId
    version: 1
    entries: []

  @render 'RouteTableEdit',
    data: -> rt

Router.route '/~~/packages/:packageId/route-tables/edit/:_id', ->
  {_id, packageId} = @params
  rt = DB.RouteTable.findOne {_id, packageId},
    reactive: false

  # no resource yet? be reactive
  unless rt
    return DB.RouteTable.findOne {_id, packageId}

  rt.version += 1 # it's a draft

  @render 'RouteTableEdit',
    data: -> rt


Template.RouteTableEdit.onCreated ->
  @routes = new ReactiveArray @data.entries
  @selected = new ReactiveVar null

Template.RouteTableEdit.helpers
  templates: ->
    DB.Template.find {@packageId}

  routes: ->
    Template.instance().routes.list()

  isSelected: ->
    @path? and @path is Template.instance().selected.get()

  hasSelection: ->
    !!Template.instance().selected.get()?

  # Called by entry editor with new version or nothing to cancel
  applyEdit: ->
    {selected, routes} = Template.instance()
    (newRoute) ->

      # Cancels will pass null
      unless newRoute?
        # Null routes just get removed
        if selected.get() is ''
          idx = routes.findIndex (r) => r.path is ''
          if idx isnt -1
            routes.splice idx, 1

        selected.set null
        return

      # Blank paths can't be saved
      if selected.get() is '' and !newRoute.path.length
        alert "Path is required for routes"
        return

      # If path is changed, make sure it's available
      if selected.get() != newRoute.path
        if routes.some((r) => r.path is newRoute.path)
          alert "Path fragment #{newRoute.path} already exists in table"
          return

      # Replace route with new object
      idx = routes.findIndex (r) => r.path is selected.get()
      if idx isnt -1
        routes.splice idx, 1, newRoute
        selected.set(null)


Template.RouteTableEdit.events
  'click .save-table': (evt) ->
    evt.preventDefault()

    # TODO: update model from DOM
    @name = $('[name=name]').val() || null
    @layout = $('[name=layout]').val() || null
    @entries = Template.instance().routes.array()

    try
      isNew = not @_id
      @save()
      if isNew
        Router.go "/~~/packages/#{@packageId}/route-tables/edit/#{@_id}"
      else
        @version += 1 # start another draft

    catch err
      alert err.message

  'click .add-entry': (evt) ->
    evt.preventDefault()
    {routes, selected} = Template.instance()

    # Check for null route first
    idx = routes.findIndex (r) => r.path is ''
    if idx isnt -1
      alert "There is already a blank route, won't add another"
      return

    # Add/select new null route
    routes.push
      path: ''
      type: 'template'
    selected.set ''

  ##############################
  # actions on existing routes

  'click .edit': ->
    {selected} = Template.instance()
    selected.set @path

  'click .remove': ->
    {routes} = Template.instance()
    idx = routes.findIndex (r) => r.path is @path
    if idx >= 0
      routes.splice idx, 1

  'click .move-up': ->
    {routes} = Template.instance()
    idx = routes.findIndex (r) => r.path is @path
    if idx > 0
      console.log routes.map (r) -> r.path
      routes.splice idx-1, 2, routes[idx], routes[idx-1]
      console.log routes.map (r) -> r.path

  'click .move-down': ->
    {routes} = Template.instance()
    idx = routes.findIndex (r) => r.path is @path
    if idx >= 0 and idx < routes.length - 1
      routes.splice idx, 2, routes[idx+1], routes[idx]
