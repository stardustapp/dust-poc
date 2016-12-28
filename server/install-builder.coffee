Meteor.startup ->
  unless DB.Package.findOne(_id: 'build')
    Meteor.call '/repo/install-package', 'build', (err) -> if err
      console.log "Couldn't install build app:", err
