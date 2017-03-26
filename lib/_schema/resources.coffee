##################
## Resources
# Injectable code and config that defines app behavior
# Has similar roles to Angular recipes

DB.Resources = new Mongo.Collection 'resources'
DB.Resource = Astro.Class.create
  name: 'Resource'
  collection: DB.Resources
  typeField: 'type'
  fields:
    packageId : type: String, immutable: true
    name      : type: String
    version   : type: Number
    # injects   : type: [String]

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
    entries   : type: [DB.RouteTableEntry], default: -> []

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
    html      : type: String, default: '<div>\n  Hello World\n</div>'
    css       : type: String, optional: true
    scss      : type: String, optional: true
    scripts   : type: [DB.TemplateScript], default: -> []

##########################
## Custom Record Classes

DB.TemplateScriptType = Astro.Enum.create
  name: 'TemplateScriptType'
  identifiers: [
    'on-render', 'on-create', 'on-destroy',
    'helper', 'event', 'hook'
  ]

# TODO: check that Type resolves
DB.RecordField = Astro.Class.create
  name: 'RecordField'
  fields:
    key      : type: String
    type     : type: String
      # core:string/number/boolean/date/object or custom
    isList   : type: Boolean, default: false
    optional : type: Boolean, default: false
    immutable: type: Boolean, default: false
    default  : type: String, optional: true # as [E]JSON string
    # TODO: enum, transient, mapping

# TODO: don't let these rename
# TODO: check that Base resolves
DB.CustomRecord = DB.Resource.inherit
  name: 'CustomRecord'
  fields:
    base      : type: String, default: 'core:Record'
    dataScope : type: String, default: 'global' # or group or user
    fields    : type: [DB.RecordField], default: -> []

    # Behaviors
    # TODO: need to be dynamic, w/ helpers
    timestamp : type: Boolean, default: false
    slugField : type: String, optional: true

################
## Data publications

DB.DocLocator = Astro.Class.create
  name: 'DocLocator'
  fields:
    recordType : type: String, default: 'core:Record'
    filterBy   : type: String, optional: true
    sortBy     : type: String, optional: true
    fields     : type: String, optional: true
    limitTo    : type: Number, optional: true
DB.DocLocator.extend
  fields:
    children   : type: [DB.DocLocator], default: -> []

DB.Publication = DB.Resource.inherit
  name: 'Publication'
  fields:
    # TODO: security, auth check
    recordType : type: String, default: 'core:Record'
    filterBy   : type: String, optional: true
    sortBy     : type: String, optional: true
    fields     : type: String, optional: true
    limitTo    : type: Number, optional: true
    children   : type: [DB.DocLocator], default: -> []


################
## Server methods

DB.ServerMethod = DB.Resource.inherit
  name: 'ServerMethod'
  fields:
    # TODO: auth/security setting
    coffee  : type: String, optional: true
    js      : type: String, optional: true
    injects : type: [String], default: -> []


################
## Dependencies

DB.Dependency = DB.Resource.inherit
  name: 'Dependency'
  fields:
    childPackage : type: String, optional: true
    isOptional   : type: Boolean, default: false
