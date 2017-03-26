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

sass = new SassCompiler
Meteor.methods '/builtin/sass/compile': (source, extension) ->
  check source, String
  check extension, String

  res = sass.compileOneFile
    getDisplayPath: -> 'styling.' + extension
    getExtension: -> extension
    getBasename: -> 'styling'
    getPackageName: -> 'stardust'
    getPathInPackage: -> 'styling.' + extension
    getContentsAsBuffer: -> new Buffer source
    error: ({message, sourcePath}) ->
      throw new Meteor.Error 'scss-error', message
  , []

  if res.referencedImportPaths.length
    throw new Meteor.Error 'no-sass-imports', "
      Sass imports may not be used yet"

  {css, sourceMap} = res.compileResult
  css: css.slice(0, css.lastIndexOf('\n')) # sourcemap comment
  sourceMap: sourceMap
