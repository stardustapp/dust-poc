class Document
  constructor: (@table, @record) ->
    console.log @table, @record

class Table
  constructor: (@name) ->

  meta: ->
    unless @_meta ?= DB.Table.findOne {@name}
      throw new Error "No such table #{@name}"
    return @_meta

  # Find single doc by hashKey and sortKey if any
  findOne: (hashKey, sortKey) ->
    mongoFilter =
      packageId: @meta().packageId
      table: @meta().name
      hashKey: hashKey

    if @_meta().sortKey
      mongoFilter.sortKey = sortKey
      unless sortKey
        throw new Error "Sort key #{@_meta().sortKey} required for #{@name}"
    unless hashKey
      throw new Error "Sort key #{@_meta().sortKey} required for #{@name}"

    if record = DB.Record.findOne(mongoFilter)
      new Document(@, record)

  # Find single doc by hashKey
  findByHashKey: (hashKey) ->
    DB.Record.findOne
      packageId: @meta().packageId
      table: @meta().name
      hashKey: hashKey
    ?.data

  # Find single doc by hashKey and sortKey
  findByHashSortKey: (hashKey, sortKey) ->
    DB.Record.findOne
      packageId: @meta().packageId
      table: @meta().name
      hashKey: hashKey
      sortKey: sortKey
    ?.data

  # List child docs by sortKey
  queryByHashKey: (hashKey) ->
    DB.Record.find
      packageId: @meta().packageId
      table: @meta().name
      hashKey: hashKey
    , sort: {sortKey: 1}
    .map (rec) -> rec.data

  # List all docs
  scan: ->
    DB.Record.find
      packageId: @meta().packageId
      table: @meta().name
    , sort: {sortKey: 1}
    .map (rec) -> rec.data

  insertDoc: (doc) ->
    rec = new DB.Record
      packageId: @meta().packageId
      table: @meta().name
      scope: 'global' # TODO!
      hashKey: doc[@meta().hashKey]
      data: doc

    unless rec.hashKey
      throw new Error "
        Hash key #{@meta().hashKey} is required for #{@meta().name}"

    if @meta().sortKey
      unless rec.sortKey = doc[@meta().sortKey]
        throw new Error "
          Sort key #{@meta().sortKey} is required for #{@meta().name}"

    rec.save()
    return rec.data

# Simple caching
TABLES = {}

root.DUST = root.scriptHelpers =
  _liveTemplates: new Map

  triggerHook: (hookName, args...) ->
    if liveSet = DUST._liveTemplates.get(DUST._mainTemplate)
      liveSet.dep.depend()
      {instances} = liveSet
      if instances.size is 1
        if instance = instances.values().next().value
          instance.hook hookName, args...
      else if instances.size is 0
        console.warn "Hook", hookName,
            "can't be called - no live template"
      else
        console.warn "Hook", hookName,
            "can't be called -", instances.size, "live templates"

  params: new ReactiveVar {}

  getTable: (name) ->
    TABLES[name] ?= new Table(name)

  navigateTo: (path) ->
    if APP_ID # app is in subdomain
      Router.go path
    else
      APP_ROOT = "/~#{Session.get 'app id'}"
      Router.go APP_ROOT + path
