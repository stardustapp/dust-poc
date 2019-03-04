Meteor.startup ->
  
  unless DB.Package.findOne(_id: 'cx3ne5qq8qezspxdg')
    Meteor.call '/repo/install-package', 'cx3ne5qq8qezspxdg', (err) -> if err
      console.log "Couldn't install build-ng dependency cx3ne5qq8qezspxdg:", err

  unless DB.Package.findOne(_id: 'vmverefrydvslrh3j')
    Meteor.call '/repo/install-package', 'vmverefrydvslrh3j', (err) -> if err
      console.log "Couldn't install build-ng dependency vmverefrydvslrh3j:", err

  unless DB.Package.findOne(_id: 'build-ng')
    Meteor.call '/repo/install-package', 'build-ng', (err) -> if err
      console.log "Couldn't install build-ng app:", err

  unless DB.Package.findOne(_id: 'build-launch')
    Meteor.call '/repo/install-package', 'build-launch', (err) -> if err
      console.log "Couldn't install build-launch app:", err
