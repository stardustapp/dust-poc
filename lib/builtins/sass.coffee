BUILTINS.sass =
  Compile:
    type: 'ServerMethod'
    final: (source, extension, cb) ->
      source = source.replace /\t/g, '  '
      if cb?
        Meteor.call '/builtin/sass/compile', source, extension, (err, obj) ->
          obj.sass = source if obj?
          cb(err, obj)
      else
        obj = Meteor.call '/builtin/sass/compile', source, extension
        obj.sass = source if obj?
        return obj

return unless Meteor.isServer
sass = Npm.require 'node-sass'

Meteor.methods '/builtin/sass/compile': (source, extension) ->
  check source, String
  check extension, String

  res = try
    await new Promise (resolve, reject) -> sass.render
      sourceMap:         true
      sourceMapContents: true
      sourceMapEmbed:    false
      sourceComments:    false
      sourceMapRoot: '.'
      outFile: '.styling'
      file: 'styling.'+extension

      indentedSyntax: extension is 'sass'
      data: source

      importer: () -> throw new Error("TODO")
      includePaths: []

    , (err, out) ->
      if err then reject(err)
      else resolve(out)
  catch err
    throw new Meteor.Error 'scss-error', "Scss compiler error: #{err.message}"

  # stringify buffers
  css = res.css.toString 'utf-8'
  sourceMap = res.map.toString 'utf-8'

  css: css.slice(0, css.lastIndexOf('\n')) # sourcemap comment
  sourceMap: JSON.parse(sourceMap)
