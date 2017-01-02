currentPackage = new Meteor.EnvironmentVariable

INJECTORS = new Map
getInjector = (packageId) ->
  unless INJECTORS.has packageId
    INJECTORS.set packageId, new DustInjector {packageId}
  INJECTORS.get packageId

Meteor.methods '/records/commit': (newDoc) ->
  check newDoc.packageId, String
  check newDoc.type, String

  # Check for package existance/access
  unless DB.Package.findOne(newDoc.packageId)
    throw new Meteor.Error 'missing-package',
      "Can't commit record for unknown package #{newDoc.packageId}"

  injector = getInjector(newDoc.packageId)
  clazz = injector.get newDoc.type, 'CustomRecord'

  if newDoc.version
    rec = clazz.findOne
      packageId: newDoc.packageId
      _id: newDoc._id

    unless rec
      throw new Meteor.Error 'not-found',
        "Record #{newDoc._id} doesn't exist in #{newDoc.type}"

    unless rec.version is newDoc.version
      console.log 'Client sent version', newDoc.version,
        'of', rec.packageId, rec.type, rec._id,
        '- latest is', rec.version, '- rejecting'
      throw new Meteor.Error 'version-conflict',
        "The record has been edited by someone else.
        Please reload and try again."

    for key, val of newDoc
      rec[key] = val

  else
    rec = new clazz newDoc
    rec.version = 0

  rec.version += 1
  console.log 'Storing version', rec.version, '-', rec
  rec.save()
