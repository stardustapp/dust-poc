## Data records
# Actual data stored by the application

DB.Records = new Mongo.Collection 'records'
DB.Record = Astro.Class.create
  name: 'Record'
  collection: DB.Records
  secured: false
  fields:
    packageId : type: String
    table     : type: String
    scope     : type: String
          # global, group:asdf, user:qwert
    hashKey   : type: String
    sortKey   : type: String, optional: true
          # TODO: this should really be a number, date, string, etc
    data      : type: Object
