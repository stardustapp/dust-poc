class Table
  constructor: (@name) ->
    unless @meta = DB.Table.findOne {@name}
      throw new Error "No such table #{@name}"

  # Find single doc by hashKey
  findByHashKey: (hashKey) ->
    DB.Record.findOne
      tableId: @meta._id
      hashKey: hashKey
    ?.data

  # List child docs by sortKey
  queryByHashKey: (hashKey) ->
    DB.Record.find
      tableId: @meta._id
      hashKey: hashKey
    , sort: {sortKey: 1}
    .map (rec) -> rec.data

  # List all docs
  scan: ->
    DB.Record.find
      tableId: @meta._id
    , sort: {sortKey: 1}
    .map (rec) -> rec.data

  insertDoc: (doc) ->
    rec = new DB.Record
      tableId: @meta._id
      hashKey: doc[@meta.hashKey]
      data: doc

    if @meta.sortKey
      unless rec.sortKey = doc[@meta.sortKey]
        throw new Error "
          Sort key #{@meta.sortKey} is required for #{@meta.name}"

    rec.save()
    return rec.data

# Simple caching
TABLES = {}

root.scriptHelpers =

  getTable: (name) ->
    TABLES[name] ?= new Table(name)
