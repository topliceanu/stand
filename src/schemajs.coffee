_ = require 'underscore'
azure = require 'azure-storage'
schemajs = require 'schemajs'


# Make all OData types be accepted by schemajs.

schemajs.type['Edm.String'], (value) ->
    _.isString value

schemajs.type['Edm.Binary'], (value) ->
    _.isString value

schemajs.type['Edm.Int64'], (value) ->
    (_.isNumber value) or (_.isString value and not _.isNaN parseInt value)

schemajs.type['Edm.Int32'], (value) ->
    (_.isNumber value) or (_.isString value and not _.isNaN parseInt value)

schemajs.type['Edm.Double'], (value) ->
    (_.isNumber value) or (_.isString value and not _.isNaN parseInt value)

schemajs.type['Edm.DateTime'], (value) ->
    _.isDate value

schemajs.type['Edm.Guid'], (value) ->
    _.isString value

schemajs.type['Edm.Boolean'], (value) ->
    _.isBoolean value


module.exports = schemajs
