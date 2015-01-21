/* This example describes how to create your own table model.
 * In this case we want to store urls and their minified version.
 *
 * We extend the base Model class to provide a required tableName and a schema.
 * The PartitionKey will be fixed to 'url' and the RowKey will be the shortened
 * version of the url.
 *
 * We add a static method called `.store()` which will insert new minified urls.
 * This method will return a Q.Promise which resolves when the data is persisted
 * in the Table Service.
 *
 * Also, to demonstrate how to easily query the created dataset, this class
 * also has a .find() static method returning a promise which resolves with
 * the url behind the minified url.
 *
 * To run:
 * $ npm install stand
 *
 */
util = require('util');

stand = require('stand');


// Configure connection to you Storage Account. REPLACE THESE WITH YOUR OWN.
stand.service.connect({account: 'my-account', accessKey: 'long access key'});

// Url class extends from stand.Model.
var Url = function () {
    stand.Model.call(this);
};
util.inherits(Url, stand.Model);

// Make sure the table name is unique.
Url.tableName = 'url';
Url.partitionKey = 'url';

// Schema is used to validate entity data before storing in the Table service.
// By default, the schema contains PartitionKey and RowKey definitions and you
// don't have to add these yourself, they are implicit.
Url.schema = {
    'Url': {type: 'string+', required: true}
};

// Method inserts a url with it's shortened version.
// For this use-case, the partition key is the same for all entities, but you
// can easily change that.
Url.store = function (shortUrl, originalUrl) {
    entity = new Url({
        'PartitionKey': Url.partitionKey,
        'RowKey': shortUrl,
        'Url': originalUrl
    });
    // When calling save, the data is first validated.
    entity.save()
};

// Method uses the Table Storage's index lookup to find the shortened url.
Url.find = function (short) {
    Url.queryEntity(Url.partitionKey, short);
};
