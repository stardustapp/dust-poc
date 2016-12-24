Router.route '/templates', ->
  @render 'TemplateList'

Template.TemplateList.helpers
  templateList: ->
    DB.Template.find({@packageId})
