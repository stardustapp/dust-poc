BUILTINS =
  core:
    Record:
      type: 'CustomRecord' # TODO
      final: DB.Record

root.DustInjector = class DustInjector
  constructor: ({@packageId}) ->
    @cache = new Map

  # No caching, loads fresh
  # TODO: support deps from children
  # name - within the package
  # package:name - from a dep
  # ($name - system resource?)
  load: (name) ->
    #console.log 'injecting', name

    if ':' in name
      [pkg, subName] = name.split(':')
      if val = BUILTINS[pkg]?[subName]
        return val

      throw new Meteor.Error 'not-found',
        "Failed to inject #{name} - builtin does not exist"

    resource = DB.Resource.findOne
      packageId: @packageId
      name: name

    unless resource then throw new Meteor.Error 'not-found',
      "Failed to inject #{name} - name could not be resolved"

    type: resource.type
    final: switch resource.type
      when 'CustomRecord' then @_injectCR(resource)
      else throw new Meteor.Error 'not-implemented',
        "#{name} was a #{resource.type} but I have no recipe for that"


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
        else throw new Meteor.Error 'field-type-error',
          "Record field type #{type} isn't a thing"
      bareType = [bareType] if field.isList

      fields[field.key] =
        type: bareType
        optional: field.optional
        immutable: field.immutable
        default: -> if field.default
          JSON.parse field.default

    behaviors: {}
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
