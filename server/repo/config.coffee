if true # Meteor.settings.AWS
  AWS.config.update
    accessKeyId: 'AKIAIFCYEL4GIQUUPLIQ'
      # Meteor.settings.AWS.accessKeyId
    secretAccessKey: '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'
      # Meteor.settings.AWS.secretAccessKey
else
  console.warn "AWS settings missing"
