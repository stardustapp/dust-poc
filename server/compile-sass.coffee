sass = new SassCompiler

root.compileSass = (source, extension) ->
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
  return css.slice(0, css.lastIndexOf('\n')) # sourcemap comment
