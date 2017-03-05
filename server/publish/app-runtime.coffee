# TODO: publish dependencies too
# use reywood:publish-composite
# https://github.com/englue/meteor-publish-composite

Meteor.publish '/app-runtime', (packageId) ->
  check packageId, String

  if packageId.startsWith 'build'
    # TODO: this is effectively auto-publish
    return [
      DB.Package.find()
      DB.Resources.find()
    ]

  # Recursively build list of dependencies
  packageIds = []
  addPkg = (pkg) ->
    return if pkg in packageIds
    packageIds.push pkg
    DB.Dependency.find(packageId: pkg).forEach (dep) ->
      addPkg dep.childPackage
  addPkg packageId

  [
    DB.App.find _id: $in: packageIds
    DB.Resources.find packageId: $in: packageIds
  ]
