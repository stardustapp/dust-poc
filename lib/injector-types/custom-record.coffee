InjectorTypes.set 'CustomRecord', (res) ->
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
