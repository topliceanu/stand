# This example describes how to create your own table model.
# In this case we want to store urls and their minified version.
#
# We extend the base Model class to provide a required tableName and a schema.
# The PartitionKey will be fixed to 'url' and the RowKey will be the shortened
# version of the url.
#
# We add a static method called `.store()` which will insert new minified urls.
# This method will return a Q.Promise which resolves when the data is persisted
# in the Table Service.
#
# Also, to demonstrate how to easy it is to query the created dataset, this
# class also has a .find() static method returning a promise which resolves
# with the persisted url model.
#
# To run:
# $ npm install stand
# $ npm install coffee-script -g
# $ # Add your own storage account credentials.
# $ coffee examples/basic-bootstrap.coffee

stand = require 'stand'


# Create a connection object for the Table Storage Service.
service = new stand.TableService 'MY-STORAGE-ACCOUNT', 'MY-LONG-ACCESS-KEY'

# Url class extends from stand.Model.
class Url extends stand.Model

    # Schema is used to validate entity data before storing in the Table service.
    # By default, the schema contains PartitionKey RowKey and Timestamp definitions
    # and you don't have to add these yourself, they are implicit.
    @schema:
        # type 'Edm.String' is used to serialize data to tables endpoint.
        'Url': {type: 'Edm.String', required: true}

# Register the new model. This will ensure that the table is created and ready to use.
service.register 'url', Url

# Create a new url entity.
# For this use-case, the partition key is the same for all entities, but you
# can easily change that.
url = new Url
    'PartitionKey': 'u',
    'RowKey': '2EfWx5p', # short hash.
    'Url': 'http://google.com' # original url

# To persist it, there a multiple methods available (see the docs), here we're
# using insertOrReplace() which will not check if the entity already exists and
# if it does, it will replace it with the new data.
url.insertOrReplace().then ->
    console.log 'successfully inserted the new url'

    # find() returns a stand.TableQuery which extends azure.TableQuery to
    # provide a handy .exec() method which returns a promise resolving with the
    # response data encampsulated in a Url model.
    Url.find()
        .where('RowKey eq ?', '2EfWx5p')
        .exec().then (urls) ->
            console.log "The expanded url is", (urls[0].get 'Url')
.fail (error) ->
    console.log 'Failed to execute operations', error
