Meteor.publish '/dust/publication', (appId, pubName, params={}) ->
  injector = getInjector appId
  publication = injector.get pubName, 'Publication'

  # TODO: nested / composite publishes

  publication.find(params)
