Router.route '/packages/:packageId/routes/new', ->
  route = new DB.Route
    packageId: @params.packageId
    version: 1
    actionCoffee: "->\n  @render 'Home'"

  @render 'RouteEdit',
    data: -> route

Router.route '/packages/:packageId/routes/edit/:_id', ->
  {_id, packageId} = @params
  route = DB.Route.findOne {_id, packageId},
    reactive: false

  # no route yet? be reactive
  unless route
    return DB.Route.findOne {_id, packageId}

  route.version += 1 # it's a draft

  @render 'RouteEdit',
    data: -> route


Template.RouteEdit.onRendered ->
  @editor = CodeMirror @$('.action-editor')[0],
    lineNumbers: true
    mode: 'coffeescript'
    theme: 'neo'
    tabSize: 2
    value: @data.actionCoffee ? ''

  # We are our own page, we have room
  @editor.setSize '100%', '100%'

#Template.RouteEdit.helpers

Template.RouteEdit.events
  'submit form': (evt) ->
    evt.preventDefault()

    @path = evt.target.path.value || null
    @name = evt.target.name.value || null

    {editor} = Template.instance()
    @actionCoffee = editor.getValue()

    # We get a lot of tabs.
    fixedCoffee = @actionCoffee.replace(/\t/g, '  ')
    if fixedCoffee isnt @actionCoffee
      editor.setValue fixedCoffee
      @actionCoffee = fixedCoffee

    Meteor.call 'compileCoffee', @actionCoffee, 'function', (err, js) =>
      if err
        alert err.message
        return

      @actionJs = js

      if @_id
        existing = DB.Route.findOne {@_id}
        if existing.version != @version - 1
          alert 'The route has been edited by someone else. Reload and try again'
          return

      try
        isNew = not @_id
        @save()
        if isNew
          Router.go "/packages/#{@packageId}/routes/edit/#{@_id}"
        else
          @version += 1 # start another draft

      catch err
        alert err.message
