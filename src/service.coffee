azure = require 'azure'


retryOperation = new azure.ExponentialRetryPolicyFilter
{accountName, accountKey} = conf.azure.storage

# Export the Azure Tables Service instance.
module.exports = (azure.createTableService accountName, accountKey)
                       .withFilter retryOperation

