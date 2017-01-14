DB.ServerMethod.extend events:
  beforeSave: (evt) -> if evt.target.coffee?
    meth = evt.target

    # CodeMirror is very easygoing about inserting tabs
    # Just never store tabs, it's easier
    meth.coffee = meth.coffee.replace /\t/g, '  '

    # Process stardust directives
    meth.injects = []
    dirRegex = /^( *)%([a-z]+) (.+)$/im
    coffee = meth.coffee.replace dirRegex, (_, ws, dir, args) =>
      args = args.split(',').map (x) -> x.trim()
      lines = switch dir
        when 'inject'
          for arg in args
            # TODO: validate existance of resource?
            # TODO: validate name syntax regex!
            meth.injects.push arg
            "#{arg} = DUST.get '#{arg}'"
        else
          throw new Meteor.Error 'invalid-directive',
            "'#{dir}' is not a valid Stardust script directive"

      return lines
        .map (l) -> "#{ws}#{l}"
        .join "\n"

    # rebind `this` to DUST
    coffee = 'DUST = @;\n' + coffee
    meth.js = compileCoffeeFunction(coffee)
