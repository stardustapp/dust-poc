DB.ServerMethod.extend events:
  beforeSave: (evt) -> if evt.target.coffee?
    meth = evt.target
    injector = getInjector(meth.packageId)

    CompileCoffee = injector.get 'coffeescript:Compile'
    res = CompileCoffee(meth.coffee)

    meth.coffee = res.coffee
    meth.js = res.js
    meth.injects = res.injects
