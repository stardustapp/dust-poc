BUILTINS.coffeescript =
  Compile:
    type: 'ServerMethod'
    final: (source, cb) ->
      source = source.replace /\t/g, '  '
      if cb?
        Meteor.call '/builtin/coffeescript/compile', source, (err, obj) ->
          obj.coffee = source if obj?
          cb(err, obj)
      else
        obj = Meteor.call '/builtin/coffeescript/compile', source
        obj.coffee = source if obj?
        return obj

return unless Meteor.isServer

compileCoffee = Meteor.wrapAsync(CoffeeCompiler.compileToJS)
compile = (source) ->
  try
    compileCoffee(source).split '\n'
  catch err
    throw new Meteor.Error 400, 'Unable to compile script.\n' + err

compileCoffeeFunction = (coffee) ->
  lines = coffee.split('\n')
    .map (line) -> '  ' + line
  lines.splice 0, 0, [
    'DUST = @'
    'return ->'
  ]...

  output = compile lines.join('\n')
  output[output.length - 2] = '});'
  output.join '\n'

Meteor.methods '/builtin/coffeescript/compile': (sourceCoffee) ->
  # Process stardust directives
  injects = []
  dirRegex = /^( *)%([a-z]+) (.+)$/im
  coffee = sourceCoffee.replace dirRegex, (_, ws, dir, args) =>
    args = args.split(',').map (x) -> x.trim()
    lines = switch dir
      when 'inject'
        for arg in args
          # TODO: validate existance of resource?
          # TODO: validate name syntax regex!
          injects.push arg
          "#{arg} = DUST.get '#{arg}'"
      else
        throw new Meteor.Error 'invalid-directive',
          "'#{dir}' is not a valid Stardust script directive"

    return lines
      .map (l) -> "#{ws}#{l}"
      .join "\n"

  js: compileCoffeeFunction(coffee)
  injects: injects
