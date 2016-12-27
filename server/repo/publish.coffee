Meteor.methods 'publish package': (packageId) ->
  check packageId, String
  s3 = new AWS.S3

  console.info 'Preparing to publish package', packageId, '...'
  pkg =
    _platform: 'stardust'
    _version: 2
    packageId: packageId
    meta: DB.Package.findOne(packageId)
    resources: DB.Resource.find({packageId}).map (r) ->
      delete r._id
      delete r.packageId
      return r

  unless pkg.meta?
    throw new Meteor.Error 'no-package',
      "Package #{packageId} doesn't exist"

  console.info 'Fetched package resources!'
  delete pkg.meta._id

  console.info 'Serializing package contents...'
  fullPkg = JSON.stringify(pkg, null, 2)
  pkg.meta.stardustVersion = pkg._version
  metaPkg = JSON.stringify(pkg.meta, null, 2)

  # TODO: only reupload meta if changed
  console.info 'Uploading package metadata...'
  s3.putObjectSync
    Bucket: 'stardust-repo'
    Key: "packages/#{packageId}.meta.json"
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
