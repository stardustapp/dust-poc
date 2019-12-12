# ONGOING MIGRATIONS!
# for the three different 'script' models,
#   moving from single 'coffee' field to a 'source' and 'lang' pairing
# (started 2019-03-09)

DB.ArbitraryScript = Astro.Class.create
  name: 'ArbitraryScript'
  fields:
    coffee  : type: String, optional: true # deprecated
    source  : type: String
    lang    : type: String
    js      : type: String
    injects : type: [String], default: -> []
  events:
    afterInit: (e) ->
      if e.target.coffee
        e.target.source = e.target.coffee
        e.target.lang = 'coffee'
        delete e.target.coffee


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

# TODO: must have at least one action
DB.RouteTableEntry = Astro.Class.create
  name: 'RouteTableEntry'
  fields:
    path         : type: String
    type         : type: String
        # template, customAction
    template     : type: String, optional: true
    # layout       : type: String, optional: true
    customAction : type: DB.ArbitraryScript, optional: true

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

DB.TemplateScript = DB.ArbitraryScript.inherit
  name: 'TemplateScript'
  fields:
    key     : type: String
    type    : type: DB.TemplateScriptType
    param   : type: String, optional: true

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
    script  : type: DB.ArbitraryScript
    # TODO: remove once migrated to @script
    coffee  : type: String, optional: true
    source  : type: String, optional: true
    lang    : type: String, optional: true
    js      : type: String, optional: true
    injects : type: [String], default: -> []
  events:
    afterInit: (e) -> if @coffee
      @script.source = @source
      @script.lang = 'coffee'
      @script.js = @js
      @script.injects = @injects

################
## Dependencies

DB.Dependency = DB.Resource.inherit
  name: 'Dependency'
  fields:
    childPackage : type: String, optional: true
    isOptional   : type: Boolean, default: false
    isExtended   : type: Boolean, default: false
