Router.route '/packages/:packageId/tables/new', ->
  table = new DB.Table
    packageId: @params.packageId

  @render 'TableNew',
    data: -> table

Template.TableNew.events
  'submit form': (evt) ->
    evt.preventDefault()

    @name = evt.target.name.value || null
    @hashKey = evt.target.hashKey.value || null
    @sortKey = evt.target.sortKey.value || null

    try
      @save()
      Router.go "/packages/#{@packageId}/tables/view/#{@_id}"

    catch err
      alert err.message
