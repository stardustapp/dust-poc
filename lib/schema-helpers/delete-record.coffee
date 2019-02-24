DB.Record.extend helpers:
  delete: (cb) -> if confirm "Really delete #{@type} #{@_id}?"
    if Meteor.isClient
      console.log 'Deleting record version', @version,
          'of', @type, @_id
      console.debug 'Doc:', JSON.stringify(@raw())

    # Only use callbacks on the client
    cb2 = if alert? then (err, res) =>
      if err
        alert err
        cb? err
      else
        cb? null

    Meteor.call '/records/hardDelete', @raw(), cb2
