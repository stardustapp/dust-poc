Router.route '/~~/packages/new-app', ->
  @render 'PackageEdit', data: ->
    new DB.App
      license: 'MIT'
      libraries: []

Router.route '/~~/packages/new-library', ->
  @render 'PackageEdit', data: ->
    new DB.Library
      _id: Random.id().toLowerCase()
      license: 'MIT'
      libraries: []

Router.route '/~~/packages/edit/:_id', ->
  {_id} = @params
  pkg = DB.Package.findOne {_id},
    reactive: false

  @render 'PackageEdit',
    data: -> pkg


Template.PackageEdit.helpers

Template.PackageEdit.events
  'submit form': (evt) ->
    evt.preventDefault()

    @_id ?= evt.target.id.value || null
    @name = evt.target.name.value || null
    @license = evt.target.license.value || null
    # @libraries = [] # TODO
    @iconUrl = evt.target.iconUrl?.value || null

    try
      @save()
      Router.go "/~~/packages/view/#{@_id}"

    catch err
      alert err.message
