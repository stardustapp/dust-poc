## Data records
# Actual data stored by the application

DB.Records = new Mongo.Collection 'records'
DB.Record = Astro.Class.create
  name: 'Record'
  collection: DB.Records
  typeField: 'type'
  fields:
    packageId : type: String, immutable: true
    #table     : type: String, optional: true
    version   : type: Number, default: 0
    scope     : type: String, immutable: true
          # global, group:asdf, user:qwert
    #hashKey   : type: String, optional: true
    #sortKey   : type: String, optional: true
          # TODO: this should really be a number, date, string, etc
    #data      : type: Object, optional: true
