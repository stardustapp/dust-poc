DB.Resource.extend helpers:
  commit: (cb) ->
    console.log 'Saving version', @version, 'of resource', @name

    isNew = DB.Resource.isNew(@)
    @callMethod 'commit', @, (err, res) =>
      if err
        alert err
        cb? err
      else
        res.isNew = isNew
        @version = res.version
        cb? null, res
