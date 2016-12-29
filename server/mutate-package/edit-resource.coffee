DB.Resource.extend meteorMethods:
  commit: (newDoc) ->

    # Clients should never touch version.
    # New documents need to get version first
    if @_isNew # TODO: private?
      if newDoc.version?
        throw new Meteor.Error 'version-conflict', "
          Version cannot be specified when creating a resource"
      @version = newDoc.version = 0
      @packageId = newDoc.packageId

      # Check for package existance/access
      unless DB.Package.findOne(@packageId)
        throw new Meteor.Error 'missing-package', "
          Can't commit resource for unknown package #{@packageId}"

    # If name is new, make sure it's not taken
    if @name isnt newDoc.name
      @name = newDoc.name
      if DB.Resource.findOne({@packageId, @name})
        throw new Meteor.Error 'name-conflict', "
           #{@packageId} already has a resource named #{@name}"

    # Check for a version match
    else if @version isnt newDoc.version
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
    return {@_id, @version} # TODO: remove _id after it's less important
