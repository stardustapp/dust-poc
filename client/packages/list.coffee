Router.route '/~~/packages', ->
  @render 'PackageList'

Template.PackageList.helpers
  appList: ->
    DB.App.find()

  libraryList: ->
    DB.Library.find()
