# Diffs local (new) against remote (old)

console.debug = (msg...) ->
  console.log "    ", msg...

Meteor.methods '/repo/diff-manifest': (packageId) ->
  check packageId, String
  console.info 'Preparing to diff package', packageId

  remote = Meteor.call '/repo/fetch-package', packageId
  local =
    _platform: 'stardust'
    _version: 3
    packageId: packageId
    meta: DB.Package.findOne(packageId)
    resources: DB.Resource.find({packageId}).map (r) ->
      delete r._id
      delete r.packageId
      return r

  diffs = []

  names = new Set
  names.add(name) for {name} in remote.resources
  names.add(name) for {name} in local.resources
  names.forEach (name) ->
    resRemote = remote.resources.find (res) -> res.name is name
    resLocal = local.resources.find (res) -> res.name is name

    if not resRemote?
      diffs.push
        type: 'created'
        path: "resources.#{name}"
        newVersion: resLocal.version
    else if not resLocal?
      diffs.push
        type: 'deleted'
        path: "resources.#{name}"
        oldVersion: resRemote.version
    else if resLocal.version != resRemote.version
      diffs.push
        type: 'changed'
        path: "resources.#{name}"
        newVersion: resLocal.version
        oldVersion: resRemote.version

  return diffs
