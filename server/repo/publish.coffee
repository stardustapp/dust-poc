Meteor.methods 'publish package': (packageId) ->
  check packageId, String
  s3 = new AWS.S3

  stripIds = (o) ->
    delete o._id
    delete o.packageId
    return o

  console.info 'Preparing to publish package', packageId, '...'
  pkg =
    _version: 1
    packageId: packageId
    meta: DB.Package.findOne(packageId)
    routes: DB.Route.find({packageId}).map(stripIds)
    tables: DB.Table.find({packageId}).map(stripIds)
    templates: DB.Template.find({packageId}).map(stripIds)

  unless pkg
    throw new Meteor.Error 'no-package',
      "Package #{packageId} doesn't exist"

  console.info 'Fetched package resources!'
  delete pkg.meta._id

  if pkg.meta.layoutId
    pkg.meta.layoutName = DB.Template.findOne(pkg.meta.layoutId).name
    delete pkg.meta.layoutId

  console.info 'Serializing package contents...'
  fullPkg = JSON.stringify(pkg, null, 2)
  pkg.meta.platformVersion = pkg._version
  metaPkg = JSON.stringify(pkg.meta, null, 2)

  # TODO: only reupload meta if changed
  console.info 'Uploading package metadata...'
  s3.putObjectSync
    Bucket: 'stardust-repo'
    Key: "packages/#{packageId}-meta.json"
    Body: metaPkg
    ACL: 'bucket-owner-full-control'

  console.info 'Uploading package contents...'
  s3.putObjectSync
    Bucket: 'stardust-repo'
    Key: "packages/#{packageId}.json"
    Body: fullPkg
    ACL: 'bucket-owner-full-control'

  console.info 'Package', packageId, 'successfully published to the repo'
  return 'Published!'
