_ = require 'underscore'
azure = require 'azure-storage'
Q = require 'q'
schemajs = require 'schemajs'

service = require './service'


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
    @deferred: Q.defer()
    @ready: null

    @build: ->
        ###
            Class method builds the azure table only once per class.
            It also builds the table validation schema.
            NOTE! Call this method when only interested in class methods.
            @static
            @return {Object} Q.promise resolves when the table
                             is ready to accept requests.
        ###
        unless @tableName
            throw new Error 'Must specify a name for the Azure Table'
        unless /^[A-Za-z][A-Za-z0-9]{2,62}$/.test @tableName
            throw new Error 'Bad name format for Azure Table'

        unless @ready?
            @ready = @deferred.promise
            (Q.ninvoke @service(), 'createTableIfNotExists', @tableName).then =>
                @deferred.resolve()
            , (error) =>
                @deferred.reject error
            @schema = _.extend {}, @defaultSchema, @schema
        return @ready

    # Method return a table service object.
    #
    # @static
    # @return {Object} instance of azure.TableService.
    @service: ->
        service.getConnection()

    # Attach class methods to manipulate and query entities and tables.
    _.each [
        'doesTableExist'
        'createTable'
        'createTableIfNotExists'
        'deleteTable'
        'deleteTableIfExists'
        'queryEntities'
        'retrieveEntity'
        'insertEntity'
        'insertOrReplaceEntity'
        'updateEntity'
        'mergeEntity'
        'insertOrMergeEntity'
        'deleteEntity'
    ], (method) =>
        @[method] = (params...) ->
            @ready.then =>
                Q.ninvoke @service(), method, @tableName, params...

    # Executes a batch query, ie. a TableBatch operation.
    #
    # @static
    # @return {Object} Q.Promise
    #
    @executeBatch: (params...) ->
        @ready.then =>
            Q.ninvoke @service(), 'executeBatch', params...

    # Builds a azure.TableQuery object and selects the given fileds.
    #
    # @static
    # @param {Array<String>} fields optional list of properties to
    #                                 select from each entity selected.
    # @return {azure.TableQuery} a query object to be executed agains the current table.
    #
    @buildQuery: (keys) ->
        azure.TableQuery.select(keys...).from(@tableName)

    # @static {Object} default table schema enforces partition and row keys.
    @defaultSchema:
        PartitionKey: {type: 'string+', required: true}
        RowKey: {type: 'string+', required: true}

    # @static {Object} table schema used for validation.
    # No more than 252 properties are allowed.
    @schema: {}

    # @static {Number} max number of properties in an entity.
    @MAX_NUM_PROPERTIES: 255

    # Validates the given input data. If valid, it will return a
    # cleaned version of the input data.
    # Also makes sure the number of properties does not exceede the limit.
    #
    # @static
    # @return {Object} Q.Promise
    #
    @validate: (data) ->
        if (_.keys data).length > @MAX_NUM_PROPERTIES
            return Q.reject new Error 'Properties limit exceeded'

        check = (schemajs.create @schema).validate data
        if check.valid is true
            return Q.resolve check.data
        else
            Q.reject new Error \
                "Validation failed: #{JSON.stringify check.erorrs}"

    ## Instance.

    # @param {Object} encampsulated data.
    data: null

    # Builds an instace of an entity and ensures the Table is correctly created.
    # It will not validate input data by default.
    #
    # @param {Object} data hash to be persisted to a table Entity.
    #
    constructor: (@data = {}) ->
        @constructor.build()

    # Attach instance methods to manipulate current entity.
    _.each [
        'insertEntity'
        'insertOrReplaceEntity'
        'updateEntity'
        'mergeEntity'
        'insertOrMergeEntity'
    ], (method) =>
        @::[method] = (params...) ->
            (@constructor.validate @data).then (cleanData) =>
                @constructor[method] cleanData, params...

    deleteEntity: (params...) ->
        @constructor.deleteEntity @data, params...

    # Validates and cleans up the wrapped data
    # then inserts or updates the current entity.
    #
    # @return {Q.Promise} resolves when the data is saved to an Entity.
    save: ->
        (@constructor.validate @data).then (cleanData) =>
            @data = cleanData
            @insertOrMergeEntity()


# Public API
module.exports = Model
