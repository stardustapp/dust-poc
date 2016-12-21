Router.route '/tables/view/:_id', ->
  {_id} = @params

  @render 'TableView',
    data: -> DB.Table.findOne {_id}
