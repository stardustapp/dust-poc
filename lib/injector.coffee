root.DustInjector = class DustInjector
  constructor: ({@packageId, @parent}) ->
    @cache = new Map
    @startInvalidator()

    # TODO: move somewhere else, use global injector
    if Meteor.isClient and not @parent
      # how bad is this?
      realMustache = Spacebars.mustache.bind(Spacebars)
      RenderSmartTag.inSmartTag = false
      Spacebars.mustache = (thing...) ->
        if RenderSmartTag.inSmartTag then thing else realMustache(thing...)

      HTML.getSmartTag = RenderSmartTag.bind(@)

  startInvalidator: ->
    DB.Resources
      .find {@packageId}, fields: {name: 1, version: 1}
      .observe
        changed: (doc) =>
          if entry = @cache.get doc.name
            console.log 'Invalidating resource', doc.name
            entry.dep?.changed()
          @cache.delete doc.name
        removed: (doc) =>
          if entry = @cache.get doc.name
            console.log 'Invalidating resource', doc.name
            entry.dep?.changed()
          @cache.delete doc.name


  # Resource injection API

  fetch: (name, typeAssertion) ->
    unless val = @cache.get(name)
      val = @load name
      # only cache in the first cache it hits
      unless val.isCached
        @cache.set name, val
        val.isCached = true
    val.dep?.depend()

    if typeAssertion?
      if val.type isnt typeAssertion
        throw new Meteor.Error 'type-fail',
          "#{name} was a #{val.type}, not a #{typeAssertion}"

    return val

  getSource: (name, typeAssertion) ->
    @fetch(name, typeAssertion).source

  get: (name, typeAssertion) ->
    @fetch(name, typeAssertion).final

  # No caching, loads fresh
  # TODO: support deps from children
  # name - within the package
  # package:name - from a dep
  # ($name - system resource?)
  load: (name) ->
    console.group? 'Injecting', name

    if ':' in name
      [pkg, subNames...] = name.split(':')
      if val = BUILTINS[pkg]?[subNames[0]]
        console.log 'Using builtin'
        console.groupEnd?()
        return val

      if dependency = @get pkg, 'Dependency'
        innerRes = dependency.fetch subNames.join(':')
        console.groupEnd?()
        return innerRes

      console.groupEnd?()
      throw new Meteor.Error 'not-found',
        "Failed to inject #{name} - builtin does not exist"

    resource = DB.Resource.findOne
      packageId: @packageId
      name: name

    unless resource
      console.groupEnd?()
      throw new Meteor.Error 'not-found',
        "Failed to inject #{name} - name could not be resolved"

    if InjectorTypes.has resource.type
      final = InjectorTypes.get(resource.type).call @, resource
    else
      console.groupEnd?()
      throw new Meteor.Error 'not-implemented',
        "#{name} was a #{resource.type} but I have no recipe for that"

    console.groupEnd?()
    type: resource.type
    source: resource
    final: final
    dep: new Tracker.Dependency
