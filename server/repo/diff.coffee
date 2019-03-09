# Diffs local (new) against remote (old)

console.debug = (msg...) ->
  console.log "    ", msg...

Meteor.methods '/repo/diff-manifest': (packageId) ->
  check packageId, String
  console.info 'Preparing to diff package', packageId

  # Represent both packages
  try
    remote = Meteor.call '/repo/fetch-package', packageId
  catch err
    if err.code is 'NoSuchKey'
      throw new Meteor.Error 'not-published',
        "There is not a version of this package on the Marketplace yet."
    throw err

  local =
    _platform: 'stardust'
    _version: 3
    packageId: packageId
    meta: DB.Package.findOne packageId
    resources: DB.Resource.find({packageId}).fetch()

  # Gather the differences
  diffs = []

  # Really only resource diffs anyway
  names = new Set
  names.add name for {name} in remote.resources
  names.add name for {name} in local.resources
  names.forEach (name) ->
    resRemote = remote.resources.find (res) -> res.name is name
    resLocal = local.resources.find (res) -> res.name is name

    diff = switch
      when not resRemote?
        type: 'created'
        name: name
        newVersion: resLocal.version
        newType: resLocal.type

      when not resLocal?
        type: 'deleted'
        name: name
        oldVersion: resRemote.version
        oldType: resRemote.type

      when resLocal.version != resRemote.version
        type: 'changed'
        name: name
        newVersion: resLocal.version
        newType: resLocal.type
        oldVersion: resRemote.version
        oldType: resRemote.type

    diffs.push diff if diff
  return diffs
