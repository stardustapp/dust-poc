compileCoffee = Meteor.wrapAsync(CoffeeCompiler.compileToJS)
compile = (source) ->
  try
    compileCoffee(source).split '\n'
  catch err
    throw new Meteor.Error 400, 'Unable to compile script.\n' + err

root.compileCoffeeFunction = (coffee) ->
  lines = coffee.split('\n')
    .map (line) -> '  ' + line
  lines.unshift 'return ->'

  output = compile lines.join('\n')
  output[output.length - 2] = '}).call();'
  output.join '\n'

Meteor.methods
  compileCoffee: (coffee) ->
    # TODO: When should this be used over 'function'?
    #  when 'block'
    #    output = compile(coffee)
    #    output[output.length - 2] = '})'
    #    output.join '\n'


    coffee = coffee.replace /\t/g, '  '

    # Process stardust directives
    dirRegex = /^( *)%([a-z]+) (.+)$/im
    coffee = coffee.replace dirRegex, (_, ws, dir, args) =>
      args = args.split(',').map (x) -> x.trim()
      lines = switch dir
        when 'inject'
          for arg in args
            # TODO: validate existance of resource?
            # TODO: validate name syntax regex!
            #injects.push arg
            "#{arg} = DUST.get '#{arg}'"
        else
          throw new Meteor.Error 'invalid-directive',
            "'#{dir}' is not a valid Stardust script directive"

      return lines
        .map (l) -> "#{ws}#{l}"
        .join "\n"

    # rebind `this` to DUST
    # this is only for code that runs on the server
    #coffee = 'DUST = @;\n' + coffee
    compileCoffeeFunction(coffee)
