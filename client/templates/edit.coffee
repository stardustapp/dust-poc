Router.route '/templates/new', ->
  template = new DB.Template
    version: 1
    scripts: []

  @render 'TemplateEdit',
    data: -> template

Router.route '/templates/edit/:_id', ->
  {_id} = @params
  template = DB.Template.findOne {_id},
    reactive: false

  # no template yet? be reactive
  unless template
    return DB.Template.findOne {_id}

  template.version += 1 # it's a draft

  @render 'TemplateEdit',
    data: -> template


Template.TemplateEdit.onCreated ->
  @scriptKey = new ReactiveVar
  if firstScript = @data.scripts?[0]
    @scriptKey.set firstScript.key

  @scriptDep = new Tracker.Dependency

Template.TemplateEdit.onRendered ->
  @editors =
    html: CodeMirror @$('.html-editor')[0],
      lineNumbers: true
      mode:
        name: 'htmlembedded'
        open: '{{'
        close: '}}'
      theme: 'neo'
      tabSize: 2
      value: @data.html ? '<div>\n  Hello World\n</div>'

    coffee: CodeMirror @$('.script-editor')[0],
      lineNumbers: true
      mode: 'coffeescript'
      theme: 'neo'
      tabSize: 2

    css: CodeMirror @$('.css-editor')[0],
      lineNumbers: true
      mode: 'css'
      theme: 'neo'
      tabSize: 2
      value: @data.css ? '.canvas {\n  \n}'

  # We are our own page, we have room
  for _, editor of @editors
    editor.setSize '100%', '100%'

  # CALL THIS BEFORE SWAPPING ACTIVE SCRIPT KEY
  @stashEditors = (cb) =>
    @data.html = @editors.html.getValue()
    @data.css = @editors.css.getValue()

    if sKey = @scriptKey.get()
      if script = @data.scripts.filter((s) -> s.key is sKey)[0]
        script.coffee = @editors.coffee.getValue()

        # We get a lot of tabs.
        fixedCoffee = script.coffee.replace(/\t/g, '  ')
        if fixedCoffee isnt script.coffee
          @editors.coffee.setValue fixedCoffee
          script.coffee = fixedCoffee

        Meteor.call 'compileCoffee', script.coffee, 'function', (err, js) =>
          if err
            alert err.message
          else
            script.js = js
            cb?()
      else cb?()
    else cb?()

  @autorun =>
    if sKey = @scriptKey.get()
      if script = @data.scripts.filter((s) -> s.key is sKey)[0]
        return @editors.coffee.setValue script.coffee ? '() ->\n  '
    @editors.coffee.setValue 'nil'

Template.TemplateEdit.helpers
  scripts: ->
    Template.instance().scriptDep.depend()
    @scripts

  scriptType: ->
    DB.TemplateScriptType.getIdentifier @type

Template.TemplateEdit.events
  'click .save-template': (evt) ->
    evt.preventDefault()

    instance = Template.instance()
    instance.stashEditors =>

      if @_id
        existing = DB.Template.findOne {@_id}
        if existing.version != @version - 1
          alert 'The template has been edited by someone else. Reload and try again'
          return
      else
        @name = instance.$('.name').val() || null

      try
        isNew = not @_id
        @save()
        if isNew
          Router.go "/templates/edit/#{@_id}"
        else
          @version += 1 # start another draft

      catch err
        alert err.message

  'click .select-script': (evt) ->
    evt.preventDefault()
    instance = Template.instance()

    instance.stashEditors()
    instance.scriptKey.set @key

  'submit .add-script': (evt) ->
    evt.preventDefault()
    instance = Template.instance()

    # Make the bare script model
    scriptType = evt.target.type.value
    script = new DB.TemplateScript
      type: DB.TemplateScriptType[scriptType]
      param: evt.target.param.value || null

    # Different scripts get different names
    switch scriptType
      when 'helper', 'event', 'hook'
        unless script.param
          alert "Helpers, events, and hooks require specifying a name parameter"
          return
        script.key = "#{scriptType}:#{script.param}"
      when 'on-create', 'on-render', 'on-destroy'
        if script.param
          alert "Template lifecycle scripts can't have a name parameter"
          return
        script.key = scriptType
      else alert "huh"; return

    # Make sure it's not a duplicate
    if @scripts.some((s) -> s.key is script.key)
      alert "Script #{script.key} already exists in template"
      instance.scriptKey.set script.key
      return

    # Add script to template
    @scripts.push script

    # Switch script manager to new script
    instance.stashEditors()
    instance.scriptDep.changed() # update script list
    instance.scriptKey.set script.key

    # Reset the addition UI
    evt.target.param.value = ''
