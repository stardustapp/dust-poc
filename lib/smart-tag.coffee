global.RenderSmartTag = (view, name) ->
  return HTML.getTag(name) unless ':' in name

  # remove arbitrary pkglocal prefix from spacebars
  if name.slice(0, 3) is 'my:'
    name = name.slice(3)
  else
    name = name
      .split ':'
      .map (str) ->
        str.slice(0, 1).toUpperCase() + str
          .slice 1
          .replace /-([a-z])/g, (d) ->
            d[1].toUpperCase()
      .join ':'

  injector = view.template.injector
  (args...) ->
    try
      template = injector.get name, 'Template'
    catch err
      console.log 'RenderSmartTag failed to get template:', err
      return HTML.getTag('div')(args...)
  
    attrs = null
    contents = null
    if args[0]?.constructor in [HTML.Attrs, Object]
      [attrs, contents...] = args
    else
      contents = args

    #if attrs?.constructor is HTML.Attrs
      # TODO: flatten the attrs

    console.log 'Providing tag', name, 'with', attrs#, contents
    parentData = Template.currentData()

    if attrs
      Blaze.With ->
        data = {}
        RenderSmartTag.inSmartTag = true
        for key, val of attrs
          if val.constructor is Function
            val2 = val()
            # TODO: when is this an array?
            val2 = val2[0] if val2?.constructor is Array
            # this is not a function when the value is a helper tag
            val2 = val2() if val2?.constructor is Function
            data[key] = val2
          else data[key] = val
        RenderSmartTag.inSmartTag = false
        return data
      , ->
        Spacebars.include template, ->
          Blaze.With (-> parentData), (-> contents)
    else
      Spacebars.include(template, -> contents)
