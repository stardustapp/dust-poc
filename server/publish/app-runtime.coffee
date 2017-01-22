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

  # TODO: include deps
  [
    DB.App.find _id: packageId
    DB.Resources.find {packageId}
    #DB.Records.find {packageId}
  ]
