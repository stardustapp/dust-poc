Meteor.methods '/repo/list-packages': ->
  {IsTruncated, Contents} = anonS3 'listObjectsV2',
    Bucket: 'stardust-repo'
    Delimiter: '/'
    Prefix: 'packages/'

  if IsTruncated
    throw new Meteor.Error 'truncated', 'More than 500 packages seen'

  Contents
    .filter ({Key}) -> Key.endsWith('.meta.json')
    .map (obj) ->
      packageId: obj.Key.slice(9,-10)
      updatedAt: obj.LastModified

Meteor.methods '/repo/get-package-meta': (packageId) ->
  check packageId, String

  {Body} = anonS3 'getObject',
    Bucket: 'stardust-repo'
    Key: "packages/#{packageId}.meta.json"

  JSON.parse Body
