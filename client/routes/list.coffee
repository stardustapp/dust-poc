#Router.route '/routes', ->
#  @render 'RouteList'

Template.RouteList.helpers
  routeList: ->
    DB.Route.find({@packageId})
