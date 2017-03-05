InjectorTypes.set 'Dependency', (res) ->
  # TODO: associate with parent injector?
  console.log res.childPackage
  new DustInjector
    packageId: res.childPackage
    parent: @
