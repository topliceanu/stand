azure = require 'azure-storage'


connection = null

exports.connect = (options = {}) ->
    options.type ?= 'plain'
    if options.type is 'plain'
        {account, accessKey, host} =  options
        connection = azure.createTableService account, accessKey, host
    else if options.type is 'sas'
        {hostUri, sasToken} = options
        connection = azure.createTableService hostUri, sasToken
    else
        throw new Error 'Unsupported credentials type'
    connection


exports.getConnection = ->
    connection
