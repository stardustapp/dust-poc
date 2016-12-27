##################
## Packages
# Has similar roles to Angular modules

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
