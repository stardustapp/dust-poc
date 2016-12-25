Router.route '/~~/packages/:packageId/tables/view/:_id', ->
  {packageId, _id} = @params

  @render 'TableView', data: ->
    DB.Table.findOne {_id, packageId}
