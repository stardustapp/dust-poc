InjectorTypes.set 'Publication', (res) ->
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

    # TODO: more security
    if Meteor.isServer
      filterBy.packageId = @injector.packageId

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
