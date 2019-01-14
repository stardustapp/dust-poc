Meteor.methods '/repo/fetch-package': (packageId) ->
  check packageId, String
  s3 = new AWS.S3

  console.info 'Fetching package contents for', packageId
  {Body} = anonS3 'getObject',
    Bucket: 'stardust-repo'
    Key: "packages/#{packageId}.json"

  console.debug 'Parsing package'
  pkg = JSON.parse Body
  pkg._originalVersion = pkg._version

  if pkg._version is 1
    console.debug "Migrating package #{packageId}, v1 => v2"
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
    console.debug "Migrating package #{packageId}, v2 => v3"
    pkg.resources
      .filter (r) -> r.type is 'Template'
      .forEach (r) -> r.scss ?= r.css
    pkg._version = 3
  #-- end version 2 migration

  return pkg
