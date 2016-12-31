##################
## Resources
# Injectable code and config that defines app behavior
# Has similar roles to Angular recipes

DB.Resources = new Mongo.Collection 'resources'
DB.Resource = Astro.Class.create
  name: 'Resource'
  collection: DB.Resources
  typeField: 'type'
  secured: false
  fields:
    packageId : type: String, immutable: true
    name      : type: String
    version   : type: Number
    # injects   : type: [String]

DB.Table = DB.Resource.inherit
  name: 'Table'
  fields:
    #dataScope : type: String, optional: true
          # global, group, user
    hashKey   : type: String, immutable: true
    sortKey   : type: String, immutable: true, optional: true
    # fields    : type: [DB.TableField], defaultValue: []


################
## Route tables

DB.RouteTableCustomAction = Astro.Class.create
  name: 'RouteTableCustomAction'
  fields:
    coffee  : type: String
    js      : type: String

# TODO: must have at least one action
DB.RouteTableEntry = Astro.Class.create
  name: 'RouteTableEntry'
  fields:
    path         : type: String
    type         : type: String
        # template, customAction
    template     : type: String, optional: true
    # layout       : type: String, optional: true
    customAction : type: DB.RouteTableCustomAction, optional: true

DB.RouteTable = DB.Resource.inherit
  name: 'RouteTable'
  fields:
    layout    : type: String, optional: true
    entries   : type: [DB.RouteTableEntry], default: []

################
## UI Templates

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

DB.Template = DB.Resource.inherit
  name: 'Template'
  fields:
    html      : type: String
    css       : type: String, optional: true
    scss      : type: String, optional: true
    scripts   : type: [DB.TemplateScript], default: []
  events:
    beforeSave: (evt) -> if Meteor.isServer
      evt.target.css = if evt.target.scss
        compileSass(evt.target.scss, 'scss')
      else null
