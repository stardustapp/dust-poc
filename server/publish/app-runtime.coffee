# TODO: publish dependencies too
# use reywood:publish-composite
# https://github.com/englue/meteor-publish-composite

Meteor.publish '/app-runtime', (packageId) ->
  check packageId, String

  # Special-case some internal apps for privileged data
  if packageId is 'build-launch'
    return [
      DB.App.find()
      DB.Resources.find(packageId: 'build-launch')
    ]
  if packageId is 'build' or packageId.startsWith 'build-'
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

    DB.Dependency.find(
      packageId: pkg
    ).forEach (dep) ->
      addPkg dep.childPackage

    # Also include packages that implicitly extend this package
    DB.Dependency.find(
      childPackage: pkg
      isExtended: true
    ).forEach (dep) ->
      addPkg dep.packageId

  addPkg packageId

  [
    DB.Package.find _id: $in: packageIds
    DB.Resources.find packageId: $in: packageIds
  ]
