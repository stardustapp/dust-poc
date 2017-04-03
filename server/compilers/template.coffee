DB.Template.extend events:
  beforeSave: (evt) ->
    tmpl = evt.target
    injector = getInjector(tmpl.packageId)

    # Compile styling
    if tmpl.scss?
      CompileSass = injector.get 'sass:Compile'
      res = CompileSass(tmpl.scss, 'scss')
      tmpl.scss = res.sass
      tmpl.css = res.css

    # Compile scripting
    for script in tmpl.scripts
      switch
        when script.coffee?
          CompileCoffee = injector.get 'coffeescript:Compile'
          res = CompileCoffee(script.coffee)

          script.coffee = res.coffee
          script.js = res.js
          # also `injects`

        else throw new Meteor.Error 'unknown-script',
          "Can't recognize template script"
