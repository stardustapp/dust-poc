INJECTORS = new Map

global.getInjector = (packageId) ->
  unless INJECTORS.has packageId
    INJECTORS.set packageId, new DustInjector {packageId}
  INJECTORS.get packageId

# TODO: age out injectors from cache
