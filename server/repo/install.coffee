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

  if pkg._version is 1
    console.log "Migrating package #{packageId}, v1 => v2"
    oldPkg = pkg
    pkg =
      _version: 2
      meta: oldPkg.meta
      resources: []

    # Combine all the routes into a table
    if oldPkg.routes.length or oldPkg.meta.layoutName
      pkg.resources.push
        name: 'RootRoutes'
        type: 'RouteTable'
        version: 1
        layout: oldPkg.meta.layoutName
        entries: oldPkg.routes.map (r) ->
          path: r.path
          type: 'customAction'
          customAction:
            coffee: r.actionCoffee
            js:     r.actionJs
    # remove layoutName from meta
    delete pkg.meta.layoutName

    for table in oldPkg.tables
      table.version = 1
      table.type = 'Table'
      delete table.dataScope # the world wasn't ready yet
      pkg.resources.push table

    for template in oldPkg.templates
      template.type = 'Template'
      delete template.dataScope # the world wasn't ready yet
      pkg.resources.push template
  #-- end version 1 migration

  if pkg._version is 2
    pkg.resources
      .filter (r) -> r.type is 'Template'
      .forEach (r) -> r.scss ?= r.css
    pkg._version = 3
  #-- end version 2 migration

  if pkg._version isnt 3
    throw new Meteor.Error 'unsupported-version',
      "This package is built for a newer or incompatible version of Stardust (#{pkg._version})"

  # TODO: install dependencies

  # Clean out existing records
  if DB.Package.findOne packageId
    console.info 'Deleting existing package resources'
    DB.Package.remove(packageId)
    DB.Resources.remove({packageId})

  # Store package metadata first
  pkg.meta._id = packageId
  DB[pkg.meta.type].insert pkg.meta

  # Create new resources
  console.info 'Creating new package resources'
  for resource in pkg.resources
    resource.packageId = packageId
    DB[resource.type].insert resource

  console.info 'Done installing package!'
  return 'Installed'
