Router.route '/~~/packages/install', ->
  @render 'PackageInstall'

Template.PackageInstall.onCreated ->
  @stage = new ReactiveVar 'select'
  @available = new ReactiveVar []
  @packageId = new ReactiveVar null
  @meta = new ReactiveVar {}

  Meteor.call '/repo/list-packages', (err, cb) =>
    if err
      alert "Can't refresh packages\n\n" + err.stack
    else
      @available.set cb

Template.PackageInstall.helpers
  availableList: ->
    Template.instance().available.get()
  stage: ->
    Template.instance().stage.get()
  meta: ->
    Template.instance().meta.get()

  existingPkg: ->
    {packageId} = Template.instance()
    DB.Package.findOne packageId.get()

Template.PackageInstall.events
  'click [href=#select]': (evt) ->
    evt.preventDefault()
    { stage, packageId, meta } = Template.instance()

    stage.set 'precheck'
    packageId.set @packageId
    meta.set {}

    Meteor.call '/repo/get-package-meta', @packageId, (err, cb) =>
      if err
        alert "Can't get metadata for #{@packageId}\n\n" + err.stack
        stage.set 'select'
      else if @packageId is packageId.get()
        meta.set cb

  'click #install': ->
    { stage, packageId, meta } = Template.instance()

    stage.set 'installing'
    Meteor.call '/repo/install-package', packageId.get(), (err, cb) =>
      if err
        alert "Can't install #{packageId.get()}\n\n" + err.stack
        stage.set 'precheck'
      else
        stage.set 'installed'

  'click [href=#list]': (evt) ->
    evt.preventDefault()
    { stage, packageId, meta } = Template.instance()

    stage.set 'select'
    packageId.set null
