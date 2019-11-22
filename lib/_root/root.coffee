global.BUILTINS = {}
global.DB = {}

# Coffeescript now wraps random things like so:
# thing = module.runModuleSetters(eval(compiled))
# Seems related to ES6. Just bypass for now.
global.module ?=
  runModuleSetters: (x) -> x
