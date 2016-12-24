Router.route '/packages/view/:_id', ->
  {_id} = @params

  @render 'PackageView',
    data: -> DB.Package.findOne {_id}
