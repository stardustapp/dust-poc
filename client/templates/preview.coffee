Router.route '/templates/preview/:_id', ->
  @render 'TemplateRender',
    data: =>
      id: @params._id
      data: @params.query
