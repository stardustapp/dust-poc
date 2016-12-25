root.DB = {}


DB.TemplateScriptType = Astro.Enum.create
  name: 'TemplateScriptType'
  identifiers: [
    'on-render', 'on-create', 'on-destroy',
    'helper', 'event', 'hook'
  ]

DB.TemplateScript = Astro.Class.create
  name: 'TemplateScript'
  fields:
    key     : type: String
    type    : type: DB.TemplateScriptType
    param   : type: String, optional: true
    coffee  : type: String
    js      : type: String

DB.Templates = new Mongo.Collection 'templates'
DB.Template = Astro.Class.create
  name: 'Template'
  collection: DB.Templates
  secured: false
  fields:
    version   : type: Number
    packageId : type: String
    name      : type: String
    html      : type: String
    css       : type: String, optional: true
    scripts   : type: [DB.TemplateScript]


DB.Packages = new Mongo.Collection 'packages'
DB.Package = Astro.Class.create
  name: 'Package'
  collection: DB.Packages
  typeField: 'type'
  secured: false
  fields:
    name      : type: String
    license   : type: String
    libraries : type: [String]
    # author    : type: String
    # privacy   : type: String, default: 'public'

DB.App = DB.Package.inherit
  name: 'App'
  fields:
    iconUrl   : type: String, optional: true
    layoutId  : type: String, optional: true

DB.Library = DB.Package.inherit
  name: 'Library'


DB.Routes = new Mongo.Collection 'routes'
DB.Route = Astro.Class.create
  name: 'Route'
  collection: DB.Routes
  secured: false
  fields:
    version   : type: Number
    packageId : type: String
    path      : type: String
    name      : type: String, optional: true

    actionCoffee : type: String
    actionJs     : type: String


DB.Tables = new Mongo.Collection 'tables'
DB.Table = Astro.Class.create
  name: 'Table'
  collection: DB.Tables
  secured: false
  fields:
    packageId : type: String
    name      : type: String
    dataScope : type: String, optional: true
          # global, group, user
    hashKey   : type: String
    sortKey   : type: String, optional: true
    #fields    : type: [DB.TableField], defaultValue: []


DB.Records = new Mongo.Collection 'records'
DB.Record = Astro.Class.create
  name: 'Record'
  collection: DB.Records
  secured: false
  fields:
    packageId : type: String
    tableId   : type: String
    scope     : type: String
          # global, group:asdf, user:qwert
    hashKey   : type: String
    sortKey   : type: String, optional: true
          # TODO: this should really be a number, date, string, etc
    data      : type: Object
