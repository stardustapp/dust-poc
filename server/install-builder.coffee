Meteor.startup ->
  unless DB.Package.findOne(_id: 'build-ng')
    Meteor.call '/repo/install-package', 'build-ng', (err) -> if err
      console.log "Couldn't install build-ng app:", err

  unless DB.Package.findOne(_id: 'build-launch')
    Meteor.call '/repo/install-package', 'build-launch', (err) -> if err
      console.log "Couldn't install build-launch app:", err
