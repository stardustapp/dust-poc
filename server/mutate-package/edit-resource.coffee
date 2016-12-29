DB.Resource.extend meteorMethods:
  commit: (newDoc) ->

    # Clients should never touch version.
    # Check for a version match
    if @version isnt newDoc.version
      console.log 'Client sent version', newDoc.version,
        'of', @packageId, @name,
        '- latest is', @version, '- rejecting'
      throw new Meteor.Error 'version-conflict', "
        The template has been edited by someone else.
        Reload and try again."

    for key, meta of @constructor.definition.fields
      unless key in ['_id', 'type', 'packageId', 'version']
        @[key] = newDoc[key] ? null

    @version++
    result = @save() # TODO: do validations throw?

    console.log 'Committed version', @version, 'of', @packageId, @name
    return @version
