DB.Record.extend helpers:
  commit: (cb) ->
    if Meteor.isClient
      console.log 'Saving record version', @version,
          'of', @type, @_id

    # TODO: validate locally

    # Only use callbacks on the client
    cb2 = if alert? then (err, res) =>
      if err
        alert err
        cb? err
      else
        @version = res.version
        @_id = res.id
        cb? null, res

    res = Meteor.call '/records/commit', @raw(), cb2
    if Meteor.isServer
      @version = res.version
      @_id = res.id
