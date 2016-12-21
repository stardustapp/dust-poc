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
    name      : type: String
    html      : type: String
    css       : type: String, optional: true
    scripts   : type: [DB.TemplateScript], defaultValue: []


DB.Tables = new Mongo.Collection 'tables'
DB.Table = Astro.Class.create
  name: 'Table'
  collection: DB.Tables
  secured: false
  fields:
    name      : type: String
    hashKey   : type: String
    sortKey   : type: String, optional: true
    #fields    : type: [DB.TableField], defaultValue: []
