azure = require 'azure-storage'


# Instance of azure.TableService
# @private
connection = null


# Method creates a conenction object with the azure tables service.
# Supports multiple types of authentication
#  - account name & account access key
#  - connection string & account access key
#  - host uri & sas token
#
# @example
#   var rest = require('rest');
#   var connection = rest.service.connect({
#       account: 'my-dev-account',
#       accessKey: 'some-long-token'
#   });
#
# @see https://github.com/Azure/azure-storage-node#usage
# @param {Object} options
# @param options {String} type either `plain` or `sas`. Default is `plain`.
# @param options {String} account available for `plain` type connection.
# @param options {String} accessKey available for `plain` type connection.
# @param options {String} hostUri available for `sas` type connection.
# @param options {String} sasToken available for `sas` type connection.
# @return {azure.TableService} connection
#
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


# Method is used to access the connection singleton object.
#
# @private
# @return {azure.TableService} connection
#
exports.getConnection = ->
    connection
