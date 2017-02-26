InjectorTypes.set 'ServerMethod', (res) ->
  # curried function
  # args includes the callback for sure
  (args) =>
    Meteor.call '/dust/method', @packageId, @name, args...
