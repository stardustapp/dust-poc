class Table
  constructor: (@name) ->

  meta: ->
    unless @_meta ?= DB.Table.findOne {@name}
      throw new Error "No such table #{@name}"
    return @_meta

  # Find single doc by hashKey
  findByHashKey: (hashKey) ->
    DB.Record.findOne
      tableId: @meta()._id
      hashKey: hashKey
    ?.data

  # Find single doc by hashKey and sortKey
  findByHashSortKey: (hashKey, sortKey) ->
    DB.Record.findOne
      tableId: @meta()._id
      hashKey: hashKey
      sortKey: sortKey
    ?.data

  # List child docs by sortKey
  queryByHashKey: (hashKey) ->
    DB.Record.find
      tableId: @meta()._id
      hashKey: hashKey
    , sort: {sortKey: 1}
    .map (rec) -> rec.data

  # List all docs
  scan: ->
    DB.Record.find
      tableId: @meta()._id
    , sort: {sortKey: 1}
    .map (rec) -> rec.data

  insertDoc: (doc) ->
    rec = new DB.Record
      packageId: @meta().packageId
      tableId: @meta()._id
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

  getTable: (name) ->
    TABLES[name] ?= new Table(name)

  navigateTo: (path) ->
    if APP_ID # app is in subdomain
      Router.go path
    else
      APP_ROOT = "/~#{Session.get 'app id'}"
      Router.go APP_ROOT + path
