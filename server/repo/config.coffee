import { AWS } from 'meteor/peerlibrary:aws-sdk'

s3 = new AWS.S3
global.anonS3 = (method, args) ->
  blocking(s3, s3.makeUnauthenticatedRequest)(method, args)
