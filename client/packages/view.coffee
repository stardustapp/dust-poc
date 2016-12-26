Router.route '/~~/packages/view/:_id', ->
  {_id} = @params

  @render 'PackageView',
    data: -> DB.Package.findOne {_id}

Template.PackageView.events
  'click .publish-package': (evt) ->
    origText = evt.target.textContent
    evt.target.textContent = 'Publishing...'
    
    Meteor.call 'publish package', @_id, (err, res) ->
      evt.target.textContent = (err ? res).toString()
