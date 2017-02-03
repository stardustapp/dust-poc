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
                  # this is not a function when the value is a helper tag
                  val2 = val2() if val2.constructor is Function
                  data[key] = val2
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
          if entry = @cache.get doc.name
            console.log 'Invalidating resource', doc.name
            entry.dep?.changed()
          @cache.delete doc.name
        removed: (doc) =>
          if entry = @cache.get doc.name
            console.log 'Invalidating resource', doc.name
            entry.dep?.changed()
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
      when 'ServerMethod'
        resource # TODO: return call interface
      when 'Publication'
        @_injectPub(resource)
      else
        console.groupEnd?()
        throw new Meteor.Error 'not-implemented',
          "#{name} was a #{resource.type} but I have no recipe for that"

    console.groupEnd?()
    type: resource.type
    final: final
    dep: new Tracker.Dependency

  get: (name, typeAssertion) ->
    unless val = @cache.get(name)
      val = @load name
      @cache.set name, val
    val.dep?.depend()

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
        when 'core:object' then Object
        else @get field.type, 'CustomRecord'
      bareType = [bareType] if field.isList

      fields[field.key] = ((field) ->
        type: bareType
        optional: field.optional
        immutable: field.immutable
        default: -> if field.default
          JSON.parse field.default
      )(field)

    #console.log fields

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

  _injectPub: (res) ->
    # TODO: just precache all records in general for inheritance
    for {name} in DB.CustomRecord.find({@packageId}).fetch()
      @get name, 'CustomRecord'

    return new RecordPublication res, @

class RecordPublication
  constructor: (@res, @injector) ->
    @recordType = @injector.get @res.recordType, 'CustomRecord'

  find: (params={}, parents=[]) ->
    opts = {}
    if @res.sortBy?.length > 2
      opts.sort = JSON.parse(@res.sortBy)
    if @res.fields?.length > 2
      opts.fields = JSON.parse(@res.fields)
    if @res.limitTo
      opts.limit = @res.limitTo

    filterBy = JSON.parse(@res.filterBy)
    # TODO: recursive
    for key, val of filterBy
      if val?.$param?
        filterBy[key] = params[val.$param]
      else if val?.$parent?
        filterBy[key] = if val.$field?.includes '[].'
          [ary, key2] = val.$field.split '[].'
          $in: parents[val.$parent][ary]?.map((x) -> x[key2]) ? []
        else
          parents[val.$parent][val.$field ? '_id']
    console.log 'filtering by', filterBy

    @recordType.find filterBy, opts

  subscribe: (params={}) ->
    unless @res.packageId
      throw new Meteor.Error 'nested-pub-sub',
        "Only top-level publications can be subscribed to"

    if Meteor.isServer
      throw new Meteor.Error 'server-sub',
        "Servers cannot subscribe to data publications"

    if inst = Template.instance()
      inst.subscribe '/dust/publication', @res.packageId, @res.name, params
    else
      console.warn 'Using application-wide subscribe for', @res.name
      Meteor.subscribe '/dust/publication', @res.packageId, @res.name, params

  children: ->
    @res.children.map (c) =>
      new RecordPublication c, @injector
