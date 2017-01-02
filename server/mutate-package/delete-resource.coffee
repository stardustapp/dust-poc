DB.Resource.extend meteorMethods:
  hardDelete: (version) ->
    check version, Number

    # Check for a version match
    if @version isnt version
      console.log 'Client deleted version', version,
        'of', @packageId, @name,
        '- latest is', @version, '- rejecting'
      throw new Meteor.Error 'version-conflict', "
        The template has been edited by someone else.
        Reload and try again."

    @remove()

    console.log 'Deleted version', @version, 'of', @packageId, @name
