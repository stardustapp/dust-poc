root = global ? window
root.root = root

# Coffeescript now wraps random things like so:
# thing = module.runModuleSetters(eval(compiled))
# Seems related to ES6. Just bypass for now.
root.module ?=
  runModuleSetters: (x) -> x
