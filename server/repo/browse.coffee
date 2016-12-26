Meteor.methods '/repo/list-packages': ->
  s3 = new AWS.S3

  {IsTruncated, Contents} = s3.listObjectsV2Sync
    Bucket: 'stardust-repo'
    Delimiter: '/'
    Prefix: 'packages/'

  if IsTruncated
    throw new Meteor.Error 'truncated', 'More than 500 packages seen'

  Contents
    .filter ({Key}) -> Key.endsWith('-meta.json')
    .map (obj) ->
      packageId: obj.Key.slice(9,-10)
      updatedAt: obj.LastModified

Meteor.methods '/repo/get-package-meta': (packageId) ->
  check packageId, String
  s3 = new AWS.S3

  {Body} = s3.getObjectSync
    Bucket: 'stardust-repo'
    Key: "packages/#{packageId}-meta.json"

  JSON.parse Body
