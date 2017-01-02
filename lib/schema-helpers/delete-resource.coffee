DB.Resource.extend helpers:
  delete: (cb) -> if confirm "Really delete resource #{@name}?"
    console.log 'Deleting version', @version, 'of resource', @name

    @callMethod 'hardDelete', @version, (err, res) =>
      if err
        alert err
        cb? err
      else
        cb? null
