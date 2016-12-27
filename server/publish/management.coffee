# For building apps
# Don't include any actual data

Meteor.publish '/management', ->

  # TODO: this is effectively auto-publish
  [
    DB.App.find()
    DB.Resource.find()
  ]
