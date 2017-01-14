INJECTOR = new DustInjector
  packageId: APP_ID

root.DUST = root.scriptHelpers =
  _liveTemplates: new Map

  triggerHook: (hookName, args...) ->
    if liveSet = DUST._liveTemplates.get(DUST._mainTemplate)
      liveSet.dep.depend()
      {instances} = liveSet
      if instances.size is 1
        if instance = instances.values().next().value
          instance.hook hookName, args...
      else if instances.size is 0
        console.warn "Hook", hookName,
            "can't be called - no live template"
      else
        console.warn "Hook", hookName,
            "can't be called -", instances.size, "live templates"

  params: new ReactiveVar {}

  get: (name, type) ->
    INJECTOR.get(name, type)

  navigateTo: (path) ->
    if SUBDOMAIN_APPS # app is in subdomain
      Router.go path
    else if APP_ID
      APP_ROOT = "/~#{APP_ID}"
      Router.go APP_ROOT + path
    else alert "I don't know where to take you."
