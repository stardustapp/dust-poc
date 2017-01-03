BUILTINS =
  core:
    Record:
      type: 'CustomRecord' # TODO
      final: DB.Record
    Class:
      type: 'CustomRecord' # TODO
      final: Astro.Class.create(name: 'core:Class')

root.DustInjector = class DustInjector
  constructor: ({@packageId}) ->
    @cache = new Map
    @startInvalidator()

    # TODO: move somewhere else, use global injector
    if Meteor.isClient
      # how bad is this?
      realMustache = Spacebars.mustache.bind(Spacebars)
      inSmartTag = false
      Spacebars.mustache = (thing...) ->
        if inSmartTag then thing else realMustache(thing...)

      HTML.getSmartTag = (view, name) =>
        return HTML.getTag(name) unless ':' in name
        # remove arbitrary pkglocal prefix from spacebars
        if name.slice(0, 3) is 'my:'
          name = name.slice(3)

        template = @get name, 'Template'
        (args...) ->
          attrs = null
          contents = null
          if args[0]?.constructor in [HTML.Attrs, Object]
            [attrs, contents...] = args
          else
            contents = args

          #if attrs?.constructor is HTML.Attrs
            # TODO: flatten the attrs

          console.log 'Providing tag', name, 'with', attrs#, contents
          parentData = Template.currentData()

          if attrs
            Blaze.With ->
              data = {}
              inSmartTag = true
              for key, val of attrs
                if val.constructor is Function
                  val2 = val()
                  # TODO: when is this an array?
                  val2 = val2[0] if val2.length
                  data[key] = val2()
                else data[key] = val
              inSmartTag = false
              return data
            , ->
              Spacebars.include template, ->
                Blaze.With (-> parentData), (-> contents)
          else
            Spacebars.include(template, -> contents)

  startInvalidator: ->
    DB.Resources
      .find {@packageId}, fields: {name: 1, version: 1}
      .observe
        changed: (doc) =>
          console.log 'Invalidating resource', doc.name
          @cache.delete doc.name
        removed: (doc) =>
          console.log 'Invalidating resource', doc.name
          @cache.delete doc.name

  # No caching, loads fresh
  # TODO: support deps from children
  # name - within the package
  # package:name - from a dep
  # ($name - system resource?)
  load: (name) ->
    console.group? 'Injecting', name

    if ':' in name
      [pkg, subName] = name.split(':')
      if val = BUILTINS[pkg]?[subName]
        console.log 'Using builtin'
        console.groupEnd?()
        return val

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

    final = switch resource.type
      when 'CustomRecord'
        @_injectCR(resource)
      when 'Template'
        Template[compileTemplate(resource)]
      else
        console.groupEnd?()
        throw new Meteor.Error 'not-implemented',
          "#{name} was a #{resource.type} but I have no recipe for that"

    console.groupEnd?()
    type: resource.type
    final: final

  get: (name, typeAssertion) ->
    unless val = @cache.get(name)
      val = @load name
      @cache.set name, val

    if typeAssertion?
      if val.type isnt typeAssertion
        throw new Meteor.Error 'type-fail',
          "#{name} was a #{val.type}, not a #{typeAssertion}"

    return val.final

  _injectCR: (res) ->
    # TODO: scope by @packageId

    fields =
      packageId : type: String, immutable: true, default: @packageId
      scope     : type: String, immutable: true, default: res.dataScope # TODO

    for field in res.fields
      bareType = switch field.type
        when 'core:string' then String
        when 'core:number' then Number
        when 'core:boolean' then Boolean
        when 'core:date' then Date
        else @get field.type, 'CustomRecord'
      bareType = [bareType] if field.isList

      fields[field.key] =
        type: bareType
        optional: field.optional
        immutable: field.immutable
        default: -> if field.default
          JSON.parse field.default

    behaviors = {}
    if res.timestamp
      behaviors.timestamp = {}
    if res.slugField?
      behaviors.slug =
        fieldName: res.slugField

    base = @get res.base, 'CustomRecord'
    clazz = base.inherit
      name: res.name
      fields: fields
      events:
        #beforeSave: (evt) =>
        #  console.log 'inserting on evt', evt
        #  evt.currentTarget.packageId = @packageId
        #  evt.currentTarget.scope = 'global' # TODO
        beforeFind: (evt) =>
          evt.selector.packageId = @packageId
      behaviors: behaviors

    clazz
