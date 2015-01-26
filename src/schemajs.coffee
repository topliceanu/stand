_ = require 'underscore'
azure = require 'azure-storage'
schemajs = require 'schemajs'


# Make all OData types be accepted by schemajs.

schemajs.types['Edm.String'] = (value) ->
    _.isString value

schemajs.types['Edm.Binary'] = (value) ->
    _.isString value

schemajs.types['Edm.Int64'] = (value) ->
    (_.isNumber value) or (_.isString value and not _.isNaN parseInt value)

schemajs.types['Edm.Int32'] = (value) ->
    (_.isNumber value) or (_.isString value and not _.isNaN parseInt value)

schemajs.types['Edm.Double'] = (value) ->
    (_.isNumber value) or (_.isString value and not _.isNaN parseInt value)

schemajs.types['Edm.DateTime'] = (value) ->
    _.isDate value

schemajs.types['Edm.Guid'] = (value) ->
    _.isString value

schemajs.types['Edm.Boolean'] = (value) ->
    _.isBoolean value


# Public API.
module.exports = schemajs
