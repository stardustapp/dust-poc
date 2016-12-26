Meteor.methods '/repo/install-package': (packageId) ->
  check packageId, String
  s3 = new AWS.S3

  console.info 'Preparing to install package', packageId

  console.info 'Fetching package contents'
  {Body} = s3.getObjectSync
    Bucket: 'stardust-repo'
    Key: "packages/#{packageId}.json"

  console.info 'Parsing package'
  pkg = JSON.parse Body

  if pkg._version > 1
    throw new Meteor.Error 'unsupported-version',
      "This package is built for a newer version of Stardust"

  # Clean out existing records
  if DB.Package.findOne packageId
    console.info 'Deleting existing package resources'
    DB.Package.remove(packageId)
    DB.Route.remove({packageId})
    DB.Table.remove({packageId})
    DB.Template.remove({packageId})

  addId = (o) ->
    o.packageId = packageId
    return o

  console.info 'Creating new package resources'
  pkg.routes.map(addId).forEach (o) -> DB.Route.insert o
  pkg.tables.map(addId).forEach (o) -> DB.Table.insert o
  pkg.templates.map(addId).forEach (o) -> DB.Template.insert o

  pkg.meta._id = packageId
  if pkg.meta.layoutName
    pkg.meta.layoutId = DB.Template.findOne(
      name: pkg.meta.layoutName
      packageId: packageId
    )._id
    delete pkg.meta.layoutName

  DB[pkg.meta.type].insert pkg.meta

  console.info 'Done installing package!'
  return 'Installed'
