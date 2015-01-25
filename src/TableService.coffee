azure = require 'azure-storage'
Q = require 'q'


# Class encapsulates the connection to the azure table storage service
# It provides means to register Table models.
class TableService extends azure.TableSevice

    # Initiates a new Table with the Azure Storage Service.
    #
    # @see {stand.Model.build}
    # @param {String} tableName
    # @param {stand.Model} Model custom class to model the registered table.
    # @return {stand.Model} returns the adnotated model back.
    #
    register: (tableName, Model) ->
        Model.build tableName, this


module.exports = TableService