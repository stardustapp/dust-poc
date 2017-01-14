# TODO: publish dependencies too
# use reywood:publish-composite
# https://github.com/englue/meteor-publish-composite

Meteor.publish '/app-runtime', (packageId) ->
  check packageId, String

  if packageId.startsWith 'build'
    # TODO: this is effectively auto-publish
    return [
      DB.App.find()
      DB.Resources.find()
    ]

  [
    DB.App.find _id: packageId
    DB.Resources.find {packageId}
    #DB.Records.find {packageId}
  ]
