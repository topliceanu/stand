_ = require 'underscore'
azure = require 'azure'
Q = require 'q'

service = require './service'
util = require '../util'


class Model
    ###
        Class manipulates tables and entities
        on the Azure Table Storage Service.

        Tables methods are accessible from the class, ie. `Model.createTable`
        Entity methods are accessible from instance, id `model.insert()`
    ###

    # Class.

    # @static {String} table name.
    @tableName: null

    # @static {Object} instance of azure.TableService.
    @service: service

    # Attach class methods to create tables.
    _.each ['createTable', 'createTableIfNotExists'], (method) =>
        @[method] = (params...) ->
            Q.ninvoke @service, method, @tableName, params...

    # Attach class methods to manipulate and query entities and tables.
    # NOTE! Before calling this #build() must be called.
    _.each [
        'deleteTable'
        'queryEntity'
        'insertEntity'
        'insertOrReplaceEntity'
        'updateEntity'
        'mergeEntity'
        'insertOrMergeEntity'
        'deleteEntity'
    ], (method) =>
        @[method] = (params...) ->
            @ready.then =>
                Q.ninvoke @service, method, @tableName, params...

    @buildQuery: (keys) ->
        ###
            Builds a azure.TableQuery object and selects the given fileds.
            @param {Array<String>} fields - optional list of properties to
                                            select from each entity selected.
            @return {Object} instance of azure.TableQuery
        ###
        azure.TableQuery.select(keys...).from(@tableName)

    @queryEntities: (query) ->
        ###
            Executes the given query.
            It's not necesarely bound to the current table.
            @param {Object} query - instance of azure.TableQuery
            @return {Object} Q.Promise
        ###
        unless query instanceof azure.TableQuery
            return Q.reject new Error 'Expected TableQuery param.'

        @ready.then =>
             Q.ninvoke @service, 'queryEntities', query


    # Ensures the table is created in Azure Table Services.
    # This method is called only once per process.
    # @static {Object} Q.Promise resoves when the table is correctly created.
    @deferred = Q.defer()
    @ready: null

    # @static {Object} default table schema enforces partition and row keys.
    @defaultSchema:
        PartitionKey: {type: 'string+', required: true}
        RowKey: {type: 'string+', required: true}

    # @static {Object} table schema used for validation.
    # No more than 252 properties are allowed.
    @schema: {}

    # @static {Number} max number of properties in an entity.
    @MAX_NUM_PROPERTIES: 255

    @validate: (data) ->
        ###
            Validates the given input data. If valid, it will return a
            cleaned version of the input data.
            Also makes sure the number of properties does not exceede the limit.
            @static
            @return {Object} Q.Promise
        ###
        if (_.keys data).length > @MAX_NUM_PROPERTIES
            return Q.reject new Error 'Properties limit exceeded'

        check = (util.schemajs.create @schema).validate data
        if check.valid is true
            return Q.resolve check.data
        else
            Q.reject new Error "Validation failed "+
                "#{JSON.stringify check.errors} #{JSON.stringify data}"

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
            @createTableIfNotExists().then (=> @deferred.resolve()),
                                           ((error) => @deferred.reject error)
            @schema = _.extend {}, @defaultSchema, @schema
        @ready

    #@clearTable: ->
    #    ###
    #        Removes all entities from the the table.
    #        To do this in azure, one must first delete the entire table
    #        then re-create it.
    #        @return {Object} Q.Promise resolves when table is re-created.
    #    ###
    #    @deleteTable().then =>
    #        @ready = null
    #        @build()

    ## Instance.

    # @param {Object} encampsulated data.
    data: null

    constructor: (@data = {}) ->
        ###
            Builds an instace of an entity and ensures the Table
            is correctly created.
        ###
        @constructor.build()

    # Attach instance methods to manipulate current entity.
    _.each [
        'insertEntity'
        'insertOrReplaceEntity'
        'updateEntity'
        'mergeEntity'
        'insertOrMergeEntity'
        'deleteEntity'
    ], (method) =>
        @::[method] = (params...) ->
            @constructor[method] @data, params...

    save: ->
        ###
            Validates and cleans up the wrapped data
            then inserts or updates the current entity.
            @return {Object} Q.Promise
        ###
        (@constructor.validate @data).then (cleanData) =>
            @data = cleanData
            @insertOrMergeEntity()


# Public API
module.exports = Model
