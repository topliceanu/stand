util = require 'util'

azure = require 'azure-storage'


# Extends a TableQuery instance to allow execution of the requests in
# the same chain as the configurations.
#
class TableQuery extends azure.TableQuery

    # Builds the instance also attaching a Models class which allows executing
    # queryies in a chained manner.
    #
    # @param {stand.Model} Model usefull for executing the query.
    #
    constructor: (@Model) ->
        super()

    # Method executes the current table query object against the supplied
    # model class.
    #
    # @param {Object}      currentToken  A continuation token returned by a previous listing operation. Please use 'null' or 'undefined' if this is the first operation.
    # @param {Object}      options      The request options.
    # @param options {LocationMode} locationMode   Specifies the location mode used to decide which location the request should be sent to. Please see StorageUtilities.LocationMode for the possible values.
    # @param options {Number} timeoutIntervalInMs      The server timeout interval, in milliseconds, to use for the request.
    # @param options {string} payloadFormat            The payload format to use for the request.
    # @param options {bool}   autoResolveProperties    If true, guess at all property types.
    # @param options {int}    maximumExecutionTimeInMs The maximum execution time, in milliseconds, across all potential retries, to use when making this request. The maximum execution time interval begins at the time that the client begins building the request. The maximum execution time is checked intermittently while performing requests, and before executing retries.
    # @param options {bool}   useNagleAlgorithm        Determines whether the Nagle algorithm is used; true to use the Nagle algorithm; otherwise, false. The default value is false.
    # @param options {Function(entity)} entityResolver  The entity resolver. Given a single entity returned by the query, returns a modified object which is added to the entities array.
    # @param options {TableService~propertyResolver}  propertyResolver The property resolver. Given the partition key, row key, property name, property value, and the property Edm type if given by the service, returns the Edm type of the property.
    # @return {Q.Promise} resolves with the reponse from the server.
    #
    exec: (token, options) =>
        @Model.query this, token, options


# Public API.
module.exports = TableQuery
