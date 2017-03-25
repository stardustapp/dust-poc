DB.Template.extend events:
  beforeSave: (evt) ->
    tmpl = evt.target
    injector = getInjector(tmpl.packageId)

    for script in tmpl.scripts
      switch

        when script.coffee
          CompileCoffee = injector.get 'coffeescript:Compile'
          res = CompileCoffee(script.coffee)

          script.coffee = res.coffee
          script.js = res.js
          # also `injects`

        else throw new Meteor.Error 'unknown-script',
          "Can't recognize template script"
