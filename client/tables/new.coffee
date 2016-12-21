Router.route '/tables/new', ->
  table = new DB.Table

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
      Router.go "/tables/view/#{@_id}"

    catch err
      alert err.message
