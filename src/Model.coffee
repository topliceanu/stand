_ = require 'underscore'
azure = require 'azure-storage'
Q = require 'q'

schemajs = require './schemajs'
TableQuery = require './TableQuery'


# Class manipulates tables and entities on the Azure Table Storage Service.
#
# All table methods are accessible from the class, ie. `Model.createTable`
# All entity methods are accessible from instance, id `instance.insert()`
#
class Model

    # @property {String} name of the table to communicate to.
    # @static
    @tableName: null

    # Ensures the table is created in Azure Table Services.
    # This method is called only once per process.
    # @static {Object} Q.Promise resoves when the table is correctly created.
    @ready: null

    # @static {Object} instance of azure.TableService.
    @service: null

    # @static {Object} table schema used for validation. No more than 252
    # properties are allowed with the mandatory PartitionKey and RowKey.
    @schema: {}

    # @static {Object} all schemas must contain PartitionKey and RowKey. They also have a ready-only Timestamp key.
    @defaultSchema:
        PartitionKey: {type: 'Edm.String', required: true}
        RowKey: {type: 'Edm.String', required: true}
        Timestamp: {type: 'Edm.DateTime'}

    # @static {Number} max number of properties in an entity.
    @MAX_NUM_PROPERTIES: 255

    # Utility method to initiate the table model. It make sure the table exists
    # and is ready for usage.
    # This method should not be called, it is used in TableService.register
    #
    # @static
    # @see {TableService.register}
    # @param {String} tableName name of the table entity created in azure.
    @build: (tableName, service) ->
        unless (_.isString tableName) and
               (/^([A-Za-z][A-Za-z0-9]{2,62})$/.test tableName)
            throw new Error "Bad name for a table: #{tableName}"

        # Attach the table name to the Model class.
        @tableName = tableName

        # Attach a ready promise to the Model class.
        # All operations to the model will only if everything is ready.
        deferred = Q.defer()
        service.createTableIfNotExists tableName, deferred.makeNodeResolver()
        @ready = deferred.promise

        # Attach the service instance.
        @service = service

        # Build schema detection.
        @schema = _.extend {}, @defaultSchema, @schema

        return this

    # Queries data in a table. To retrieve a single entity by partition key and row key, use retrieve entity.
    #
    # @static
    # @param {azure.TableQuery} tableQuery              The query to perform. Use null, undefined, or new TableQuery() to get all of the entities in the table.
    # @param {Object}  currentToken            A continuation token returned by a previous listing operation. Please use 'null' or 'undefined' if this is the first operation.
    # @param {Object} options               The request options.
    # @param options {LocationMode} locationMode          Specifies the location mode used to decide which location the request should be sent to. Please see StorageUtilities.LocationMode for the possible values.
    # @param options {int} timeoutIntervalInMs   The server timeout interval, in milliseconds, to use for the request.
    # @param options {string} payloadFormat         The payload format to use for the request.
    # @param options {bool} autoResolveProperties If true, guess at all property types.
    # @param options {int} maximumExecutionTimeInMs  The maximum execution time, in milliseconds, across all potential retries, to use when making this request. The maximum execution time interval begins at the time that the client begins building the request. The maximum execution time is checked intermittently while performing requests, and before executing retries.
    # @param options {bool} useNagleAlgorithm         Determines whether the Nagle algorithm is used; true to use the Nagle algorithm; otherwise, false. The default value is false.
    # @param options {Function} entityResolver              The entity resolver. Given a single entity returned by the query, returns a modified object which is added to the entities array.
    # @param options {TableService.propertyResolver}  propertyResolver               The property resolver. Given the partition key, row key, property name, property value and the property Edm type if given by the service, returns the Edm type of the property.
    # @return {Q.Promise} resolves with a list of Model instances with data.
    @query: (tableQuery, currentToken, options) ->
        @ready.then =>
            Q.ninvoke @service, 'queryEntities', @tableName, tableQuery, currentToken, options
        .then ([{entries}, response]) =>
            return Q _.map entries, (entry) =>
                data = @extractData entry, @schema
                new this data

    # Builds a query object which can be executed agains the current table.
    #
    # @return {TableQuery} instance of stand.TableQuery bound to the current Model.
    @find: ->
        new TableQuery this

    # Retrieves an entity from a table.
    #
    # @static
    # @param {string}  partitionKey                                    The partition key.
    # @param {string}  rowKey                                          The row key.
    # @param {object}  options                                       The request options.
    # @param options {LocationMode}  locationMode                          Specifies the location mode used to decide which location the request should be sent to. Please see StorageUtilities.LocationMode for the possible values.
    # @param options {int}           timeoutIntervalInMs                   The server timeout interval, in milliseconds, to use for the request.
    # @param options {string}        payloadFormat                         The payload format to use for the request.
    # @param options {int}           maximumExecutionTimeInMs              The maximum execution time, in milliseconds, across all potential retries, to use when making this request. The maximum execution time interval begins at the time that the client begins building the request. The maximum execution time is checked intermittently while performing requests, and before executing retries.
    # @param options {bool}          useNagleAlgorithm                     Determines whether the Nagle algorithm is used; true to use the Nagle algorithm; otherwise, false. The default value is false.
    # @param options {TableService.propertyResolver}  propertyResolver          The property resolver. Given the partition key, row key, property name, property value, and the property Edm type if given by the service, returns the Edm type of the property.
    # @param options {Function} entityResolver        The entity resolver. Given the single entity returned by the query, returns a modified object.
    # @return {Q.Promise} resolves with a list of returned data encapsulated in models.
    #
    @retrieve: (partitionKey, rowKey, options) ->
        @ready.then =>
            Q.ninvoke @service, 'retrieveEntity', @tableName, partitionKey, rowKey, options
        .then ([entry, response]) =>
            data = @extractData entry, @schema
            return Q new this data

    # Validates the given input data. If valid, it will return a
    # cleaned version of the input data.
    # Also makes sure the number of properties does not exceede the limit.
    #
    # @static
    # @param {Object} data hash to validate against the registered schema.
    # @return {Q.Promise} resolves with an object with clean data or an error if validation failed.
    #
    @validate: (data) ->
        if (_.keys data).length > @MAX_NUM_PROPERTIES
            return Q.reject new Error 'Properties limit exceeded'

        check = (schemajs.create @schema).validate data
        if check.valid is true
            return Q.resolve check.data
        else
            Q.reject new Error \
                "Validation failed: #{JSON.stringify check.errors}"

    # Method wraps each value of the data object in Edm Entities according to the given schema.
    #
    # @static
    # @param {Object} data hash data to prepare, with format {"key": "value"}
    # @param {Object} schema object schema used to extract `type` information.
    # @return {Object} with the format {"key": {$: "edm data type", _: "value"}}
    #
    @prepareEntity: (data, schema) ->
        output = {}
        for key, value of data when key in _.keys schema
            type = schema?[key]?.type?.replace? 'Edm.', ''
            output[key] = azure.TableUtilities.entityGenerator[type]?(value) if type?
        output

    # Method extract raw data from a serialized entity. The format
    #
    # @static
    # @param {Object} entity hash with format {"key": {$: "edm data type", _: "value"}}
    # @param {Object} schema object schema used to extract `type` information.
    # @return {Object} plain data object, format {"key": "value"}
    #
    @extractData: (entity, schema) ->
        output = {}
        for key, value of entity when key in _.keys schema
            type = schema[key].type
            output[key] = switch type
                when 'Edm.Boolean' then !!value._
                when 'Edm.Int32', 'Edm.Int64' then +value._
                when 'Edm.DateTime' then new Date value._
                else value._
        output

    ## Instance.

    # @param {Object} encampsulated data.
    data: {}

    # Acts as a getter for all properties stored in this entity.
    #
    # @param {String} key the name of the property.
    # @return {Object} the value of the property.
    #
    get: (key) ->
        return @data[key]

    # Acts as a getter for all properties stored in this entity.
    #
    # @param {String} key the name of the property.
    # @param {Object} the value of the property.
    # @return {stand.Model} return the current model instance.
    #
    set: (key, value) ->
        @data[key] = value
        return this

    # Builds an instace of an entity and ensures the Table is correctly created.
    # It will not validate input data by default.
    #
    # @param {Object} data hash to be persisted to a table Entity.
    #
    constructor: (@data = {}) ->

    # Inserts a new entity into a table.
    #
    # @param {object}              options                                       The request options.
    # @param options {string}              options.echoContent]                           Whether or not to return the entity upon a successful insert. Default to false.
    # @param options {string}              options.payloadFormat]                         The payload format to use in the response, if options.echoContent is true.
    # @param options {LocationMode}        options.locationMode]                          Specifies the location mode used to decide which location the request should be sent to. Please see StorageUtilities.LocationMode for the possible values.
    # @param options {int}                 options.timeoutIntervalInMs]                   The server timeout interval, in milliseconds, to use for the request.
    # @param options {int}                 options.maximumExecutionTimeInMs]              The maximum execution time, in milliseconds, across all potential retries, to use when making this request. The maximum execution time interval begins at the time that the client begins building the request. The maximum execution time is checked intermittently while performing requests, and before executing retries.
    # @param options {bool}                options.useNagleAlgorithm]                     Determines whether the Nagle algorithm is used; true to use the Nagle algorithm; otherwise, false. The default value is false.
    # @param options {TableService~propertyResolver}   options.propertyResolver]          The property resolver. Only applied if echoContent is true. Given the partition key, row key, property name, property value, and the property Edm type if given by the service, returns the Edm type of the property.
    # @param options {Function}  options.entityResolver                          The entity resolver. Only applied if echoContent is true. Given the single entity returned by the insert, returns a modified object.
    # @return {Q.Promise} resolves with the Model instance when it is successfully persisted.
    #
    insert: (options) ->
        Q().then =>
            @constructor.validate @data
        .then (cleanData) =>
            @constructor.prepareEntity cleanData, @constructor.schema
        .then (entityData) =>
            Q.ninvoke @constructor.service, 'insertEntity', @constructor.tableName, entityData, options
        .then (response) =>
            Q this

    # Inserts or updates a new entity into a table.
    #
    # @param {Object}     options                               The request options.
    # @param options {LocationMode} locationMode                  Specifies the location mode used to decide which location the request should be sent to. Please see StorageUtilities.LocationMode for the possible values.
    # @param options {Number}  timeoutIntervalInMs           The server timeout interval, in milliseconds, to use for the request.
    # @param options {Number}  maximumExecutionTimeInMs      The maximum execution time, in milliseconds, across all potential retries, to use when making this request. The maximum execution time interval begins at the time that the client begins building the request. The maximum execution time is checked intermittently while performing requests, and before executing retries.
    # @param options {Boolean} useNagleAlgorithm             Determines whether the Nagle algorithm is used; true to use the Nagle algorithm; otherwise, false. The default value is false.
    # @return {Q.Promise} resolves when the data has been persisted successfully.
    #
    insertOrReplace: (options) ->
        Q().then =>
            @constructor.validate @data
        .then (cleanData) =>
            @constructor.prepareEntity cleanData, @constructor.schema
        .then (entityData) =>
            Q.ninvoke @constructor.service, 'insertOrReplaceEntity', @constructor.tableName, entityData, options
        .then =>
            Q this

    # Updates an existing entity within a table by replacing it. To update conditionally based on etag, set entity['.metadata']['etag'].
    #
    # @param {Object}             options                               The request options.
    # @param options {LocationMode} locationMode                  Specifies the location mode used to decide which location the request should be sent to. Please see StorageUtilities.LocationMode for the possible values.
    # @param options {Number}       timeoutIntervalInMs           The server timeout interval, in milliseconds, to use for the request.
    # @param options {Number}       maximumExecutionTimeInMs      The maximum execution time, in milliseconds, across all potential retries, to use when making this request. The maximum execution time interval begins at the time that the client begins building the request. The maximum execution time is checked intermittently while performing requests, and before executing retries.
    # @param options {Boolean}      useNagleAlgorithm             Determines whether the Nagle algorithm is used; true to use the Nagle algorithm; otherwise, false. The default value is false.
    # @return {Q.Promise} resolves when the entity is successfully replaced by the remote service.
    #
    update: (options) ->
        Q().then =>
            @constructor.validate @data
        .then (cleanData) =>
            @constructor.prepareEntity cleanData, @constructor.schema
        .then (entityData) =>
            Q.ninvoke @constructor.service, 'updateEntity', @constructor.tableName, entityData, options
        .then (response) =>
            Q this

    # Updates an existing entity within a table by merging new property values into the entity. To merge conditionally based on etag, set entity['.metadata']['etag'].
    #
    # @param {Object}       options                               The request options.
    # @param options {LocationMode} locationMode                  Specifies the location mode used to decide which location the request should be sent to. Please see StorageUtilities.LocationMode for the possible values.
    # @param options {Number}   timeoutIntervalInMs           The server timeout interval, in milliseconds, to use for the request.
    # @param options {Number}   maximumExecutionTimeInMs      The maximum execution time, in milliseconds, across all potential retries, to use when making this request. The maximum execution time interval begins at the time that the client begins building the request. The maximum execution time is checked intermittently while performing requests, and before executing retries.
    # @param options {Boolean}  useNagleAlgorithm             Determines whether the Nagle algorithm is used; true to use the Nagle algorithm; otherwise, false. The default value is false.
    # @return {Q.Promise} resolves when the entity is merged with the new data successfully.
    #
    merge: (options) ->
        Q().then =>
            @constructor.validate @data
        .then (cleanData) =>
            @constructor.prepareEntity cleanData, @constructor.schema
        .then (entityData) =>
            Q.ninvoke @constructor.service, 'mergeEntity', @constructor.tableName, entityData, options
        .then =>
            Q this

    # Inserts or updates an existing entity within a table by merging new property values into the entity.
    #
    # @param {Object}       options                               The request options.
    # @param options {LocationMode} locationMode                  Specifies the location mode used to decide which location the request should be sent to. Please see StorageUtilities.LocationMode for the possible values.
    # @param options {Number}  timeoutIntervalInMs           The server timeout interval, in milliseconds, to use for the request.
    # @param options {Number}  maximumExecutionTimeInMs      The maximum execution time, in milliseconds, across all potential retries, to use when making this request. The maximum execution time interval begins at the time that the client begins building the request. The maximum execution time is checked intermittently while performing requests, and before executing retries.
    # @param options {Boolean} useNagleAlgorithm             Determines whether the Nagle algorithm is used; true to use the Nagle algorithm; otherwise, false. The default value is false.
    # @return {Q.Promise} resolves when the entity is successfully persisted.
    #
    insertOrMerge: (options) ->
        Q().then =>
            @constructor.validate @data
        .then (cleanData) =>
            @constructor.prepareEntity cleanData, @constructor.schema
        .then (entityData) =>
            Q.ninvoke @constructor.service, 'insertOrMergeEntity', @constructor.tableName, entityData, options
        .then =>
            Q this

    # Deletes an entity within a table. To delete conditionally based on etag, set entity['.metadata']['etag'].
    #
    # @param {Object}  options                               The request options.
    # @param options {LocationMode} locationMode                  Specifies the location mode used to decide which location the request should be sent to. Please see StorageUtilities.LocationMode for the possible values.
    # @param options {Number}  timeoutIntervalInMs           The server timeout interval, in milliseconds, to use for the request.
    # @param options {Number}  maximumExecutionTimeInMs      The maximum execution time, in milliseconds, across all potential retries, to use when making this request. The maximum execution time interval begins at the time that the client begins building the request. The maximum execution time is checked intermittently while performing requests, and before executing retries.
    # @param options {Boolean} useNagleAlgorithm             Determines whether the Nagle algorithm is used; true to use the Nagle algorithm; otherwise, false. The default value is false.
    # @return {Q.Promise} resolves when the entity is successfully removed.
    #
    delete: (options) ->
        Q().then =>
            @constructor.validate @data
        .then (cleanData) =>
            @constructor.prepareEntity cleanData, @constructor.schema
        .then (entityData) =>
            Q.ninvoke @constructor.service, 'deleteEntity', @constructor.tableName, entityData, options


# Public API
module.exports = Model
