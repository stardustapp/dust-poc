s3 = new AWS.S3
root.anonS3 = (method, args) ->
  blocking(s3, s3.makeUnauthenticatedRequest)(method, args)
