DB.Record.extend helpers:
  commit: (cb) ->
    console.log 'Saving record version', @version,
        'of', @type, @_id

    # TODO: validate locally

    Meteor.call '/records/commit', @raw(), (err, res) =>
      if err
        if alert?
          alert err
        else
          console.log err.message
        cb? err
      else
        @version = res.version
        @_id = res.id
        cb? null, res
