Meteor.methods '/repo/install-package': (packageId) ->
  check packageId, String

  console.info 'Preparing to install package', packageId
  pkg = Meteor.call '/repo/fetch-package', packageId

  if pkg._version isnt 3
    throw new Meteor.Error 'unsupported-version',
      "This package is built for a newer or incompatible version of Stardust (#{pkg._version})"

  # TODO: install dependencies

  # Clean out existing records
  if DB.Package.findOne packageId
    console.debug 'Deleting existing package resources'
    DB.Package.remove(packageId)
    DB.Resources.remove({packageId})

  # Store package metadata first
  pkg.meta._id = packageId
  DB[pkg.meta.type].insert pkg.meta

  # Create new resources
  console.debug 'Creating new package resources'
  for resource in pkg.resources
    resource.packageId = packageId
    DB[resource.type].insert resource

  console.info 'Done installing package', packageId, '!!'
  return 'Installed'
