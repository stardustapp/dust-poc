Router.route '/tables', ->
  @render 'TableList'

Template.TableList.helpers
  tableList: ->
    DB.Table.find()
