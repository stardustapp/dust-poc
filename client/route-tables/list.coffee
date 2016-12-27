#Router.route '/routes', ->
#  @render 'RouteList'

Template.RouteTableList.helpers
  routeTableList: ->
    DB.RouteTable.find({@packageId})
