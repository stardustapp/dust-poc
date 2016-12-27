Template.RouteEdit.onCreated ->
  @actionType = new ReactiveVar @data.route.type

Template.RouteEdit.helpers
  templates: ->
    DB.Template.find
      packageId: @packageId

  actionType: ->
    Template.instance().actionType.get()

Template.RouteEdit.events
  'change [name=actionType]': (evt) ->
    Template.instance().actionType.set evt.target.value

    switch evt.target.value
      when 'customAction'
        # TODO: apply this default without editing @route
        @route.customAction ?=
          coffee: "(params...) ->\n  @render 'Home'"

  'click .entry-cancel': ->
    @doneCb()

  'click .entry-done': ->
    newRoute =
      path: $('[name=path]').val() || null
      type: Template.instance().actionType.get()

    switch newRoute.type
      when 'template'
        newRoute.template = $('[name=template]').val()
        # TODO: check template exists?
        @doneCb(newRoute)

      when 'customAction'
        coffee = $('textarea[name=coffee]').val()
            .replace(/\t/g, '  ')

        Meteor.call 'compileCoffee', coffee, 'function', (err, js) =>
          if err
            alert err.message
          else
            newRoute.customAction = {coffee, js}
            @doneCb(newRoute)
