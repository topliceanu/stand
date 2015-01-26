azure = require 'azure-storage'
Q = require 'q'


# Class encapsulates the connection to the azure table storage service
# It provides means to register Table models.
#
class TableService extends azure.TableService

    # Creates a new connection to the Azure Table Storage Service.
    #
    # @see {azure.TableService}
    # @param {String} storageAccountOrConnectionString The storage account or the connection string.
    # @param {String} storageAccessKey The storage access key.
    # @param {Object} host  The host address. To define primary only, pass a string. Otherwise 'host.primaryHost' defines the primary host and 'host.secondaryHost' defines the secondary host.
    # @param {String} sasToken The Shared Access Signature token.
    #
    constructor: ->
        super arguments..

    # Initiates a new Table with the Azure Storage Service.
    #
    # @see {stand.Model.build}
    # @param {String} tableName
    # @param {stand.Model} Model custom class to model the registered table.
    # @return {stand.Model} returns back the adnotated model.
    #
    register: (tableName, Model) ->
        Model.build tableName, this


# Public API.
module.exports = TableService
