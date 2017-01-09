INJECTORS = new Map

root.getInjector = (packageId) ->
  unless INJECTORS.has packageId
    INJECTORS.set packageId, new DustInjector {packageId}
  INJECTORS.get packageId

# TODO: age out injectors from cache
