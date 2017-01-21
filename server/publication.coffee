Meteor.publishComposite '/dust/publication', (appId, pubName, params={}) ->
  injector = getInjector appId
  publication = injector.get pubName, 'Publication'

  # TODO: nested / composite publishes

  console.log 'hi', pubName

  find: -> publication.find(params, [])
  children: publication.children().map (x) -> childPub x, params

childPub = (pub, params) ->
  find: (parents...) -> pub.find(params, parents)
  children: pub.children().map (x) -> childPub x, params
