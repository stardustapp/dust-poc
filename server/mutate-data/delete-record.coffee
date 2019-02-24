Meteor.methods '/records/hardDelete': (doc) ->
  check doc.packageId, String
  check doc.type, String
  check doc._id, String
  check doc.version, Number

  # Check for package existance/access
  unless DB.Package.findOne(doc.packageId)
    throw new Meteor.Error 'missing-package',
      "Can't commit record for unknown package #{doc.packageId}"

  injector = getInjector(doc.packageId)
  clazz = injector.get(doc.type, 'CustomRecord')

  rec = clazz.findOne
    packageId: doc.packageId
    _id: doc._id

  unless rec
    throw new Meteor.Error 'not-found',
      "Record #{doc._id} doesn't exist in #{doc.type}"

  unless rec.version is doc.version
    console.log 'Client deleted version', doc.version,
      'of', rec.packageId, rec.type, rec._id,
      '- latest is', rec.version, '- rejecting'
    throw new Meteor.Error 'version-conflict',
      "The record has been edited by someone else.
      Please reload and try again."

  rec.remove()
  console.log 'Deleted version', doc.version, 'of', doc.packageId, doc.type, doc._id
  true
