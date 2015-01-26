azure = require 'azure-storage'
Q = require 'q'


# Class encapsulates the connection to the azure table storage service
# It provides means to register Table models.
#
class TableService extends azure.TableService

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
