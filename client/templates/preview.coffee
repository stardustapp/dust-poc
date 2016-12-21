Router.route '/templates/preview/:_id', ->
  {_id} = @params
  #template = DB.Template.findOne {_id},
  #  reactive: false
  #template.version += 1 # it's a draft

  @render 'TemplateRender',
    data: ->
      id: 'aMJ8dt786JobsWT9a'
      data:
        time: '10:05 AM'
        weather: '86°F'
        location: 'Paradise'
        title: 'Bitcoin Exchange Rate'
