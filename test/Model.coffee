azure = require 'azure-storage'
chai = require 'chai'
Q = require 'q'

Model = require '../src/Model'
TableQuery = require '../src/TableQuery'
schemajs = require '../src/schemajs'


# NOTE! In order to make tests work, please set global environment variables:
# AZURE_STORAGE_CONNECTION_STRING or AZURE_STORAGE_ACCOUNT
# AZURE_STORAGE_ACCESS_KEY
#
describe 'Model', ->
    @timeout 15000

    before (done) ->
        @testTableName = 'user'
        @service = azure.createTableService()
        @service.createTableIfNotExists @testTableName, done

    after (done) ->
        @service.deleteTableIfExists @testTableName, done

    describe '.build()', ->

        it 'should correctly configure the model', (done) ->
            class User extends Model
                @schema:
                    name: {type: 'Edm.String', max: 255}

            User.build @testTableName, @service

            chai.assert.equal User.tableName, @testTableName,
                'should have stored the table name'

            expected =
                PartitionKey: {type: 'Edm.String', required: true}
                RowKey: {type: 'Edm.String', required: true}
                Timestamp: {type: 'Edm.DateTime'}
                name: {type: 'Edm.String', max: 255}
            chai.assert.deepEqual User.schema, expected,
                'should have merged the defined schema with the implicit required fields'

            chai.assert.equal User.service, @service,
                'should have attached the service intance to the model'

            chai.assert.ok Q.isPromise User.ready,
                'should be a promise resolving when the table is ready'

            User.ready.then =>
                Q.ninvoke @service, 'doesTableExist', @testTableName
            .then ([tableExists, body]) ->
                chai.assert.isTrue tableExists, 'table should be ready for use'
            .then (-> done()), done

    describe '.query()', ->

        before (done) ->
            Q().then =>
                gen = azure.TableUtilities.entityGenerator
                @me =
                    PartitionKey: gen.String 'users'
                    RowKey: gen.String 'me'
                    name: gen.String 'alexandru topliceanu'
                Q.ninvoke @service, 'insertEntity', @testTableName, @me
            .then (-> done()), done

        after (done) ->
            @service.deleteEntity @testTableName, @me, done

        it 'should execute a tableQuery object against a table', (done) ->
            class User extends Model
                @schema:
                    name: {type: 'Edm.String', max: 255}
            User.build @testTableName, @service

            tableQuery = new azure.TableQuery()
                .where('RowKey eq ?', 'me')
            (User.query tableQuery).then (results) =>
                chai.assert.isArray results, 'should have returned an array'
                chai.assert.lengthOf results, 1, 'should return one elem'
                chai.assert.instanceOf results[0], Model,
                    'should return a model instance'
                chai.assert.equal results[0].data.PartitionKey, 'users'
                chai.assert.equal results[0].data.RowKey, 'me'
                chai.assert.equal results[0].data.name, 'alexandru topliceanu'
            .then (-> done()), done

    describe '.find()', ->

        before (done) ->
            Q().then =>
                gen = azure.TableUtilities.entityGenerator
                @me =
                    PartitionKey: gen.String 'users'
                    RowKey: gen.String 'me'
                    name: gen.String 'topli'
                    age: gen.Int32 28
                    active: gen.Boolean true
                Q.ninvoke @service, 'insertEntity', @testTableName, @me
            .then (-> done()), done

        after (done) ->
            @service.deleteEntity @testTableName, @me, done

        it 'should build and run a tableQuery against the current table', (done) ->
            class User extends Model
                @schema:
                    name: {type: 'Edm.String', max: 255}
                    age: {type: 'Edm.Int32'}
                    active: {type: 'Edm.Boolean'}
            User.build @testTableName, @service

            query = User.find()
            chai.assert.instanceOf query, TableQuery,
                'should have created a new instance of TableQuery'

            query.select('name', 'age')
                 .top(1)
                 .where('RowKey eq ?', 'me')

            query.exec().then (results) ->
                chai.assert.isArray results, 'should have returned an array'
                chai.assert.lengthOf results, 1, 'should return one elem'
                chai.assert.instanceOf results[0], Model,
                    'should return a model instance'
                chai.assert.isUndefined results[0].data.PartitionKey,
                    'we did not select the PartitionKey'
                chai.assert.isUndefined results[0].data.RowKey,
                    'we did not select the RowKey'
                chai.assert.isUndefined results[0].data.Timestamp,
                    'we did not select the Timestamp'
                chai.assert.equal results[0].data.name, 'topli'
                chai.assert.equal results[0].data.age, 28
            .then (-> done()), done

    describe '.get()', ->

        it 'should retrieve property value', ->
            class User extends Model
                @schema:
                    name: {type: 'Edm.String', max: 255}
                    age: {type: 'Edm.Int32'}
                    active: {type: 'Edm.Boolean'}
            User.build @testTableName, @service

            user = new User
                name: 'me'
                age: 28
                active: false
            chai.assert.equal user.get('name'), 'me', 'should return data'

    describe '.set()', ->

        it 'should set property value', ->
            class User extends Model
                @schema:
                    name: {type: 'Edm.String', max: 255}
                    age: {type: 'Edm.Int32'}
                    active: {type: 'Edm.Boolean'}
            User.build @testTableName, @service

            user = new User
                name: 'me'
                age: 28
                active: false
            user.set 'age', 38
            chai.assert.equal user.data.age, 38, 'should return user age'

    describe '.retrieve()', ->

        before (done) ->
            Q().then =>
                gen = azure.TableUtilities.entityGenerator
                @me =
                    PartitionKey: gen.String 'users'
                    RowKey: gen.String 'me'
                    name: gen.String 'alexandru topliceanu'
                Q.ninvoke @service, 'insertEntity', @testTableName, @me
            .then (-> done()), done

        after (done) ->
            @service.deleteEntity @testTableName, @me, done

        it 'should return the entity selected', (done) ->
            class User extends Model
                @schema:
                    name: {type: 'Edm.String', max: 255}
            User.build @testTableName, @service

            (User.retrieve 'users', 'me').then (model) =>
                chai.assert.instanceOf model, Model, 'should return a model'
                chai.assert.equal model.data.PartitionKey, 'users'
                chai.assert.equal model.data.RowKey, 'me'
                chai.assert.equal model.data.name, 'alexandru topliceanu'
            .then (-> done()), done

    describe '.prepareEntity()', ->

        it 'should format raw data into azure entity data', ->
            schema =
                'name': {type: 'Edm.String'}
                'age': {type: 'Edm.Int32'}
                'birth': {type: 'Edm.DateTime'}
                'active': {type: 'Edm.Boolean'}
            data =
                'name': 'alex'
                'age': 29
                'birth': new Date
                'active': true
            expected =
                'name': {$: 'Edm.String', _: 'alex'}
                'age': {$: 'Edm.Int32', _: 29}
                'birth': {$: 'Edm.DateTime', _: data.birth}
                'active': {$: 'Edm.Boolean', _: true}
            actual = Model.prepareEntity data, schema
            chai.assert.deepEqual expected, actual,
                'should correctly format the data'

    describe '.extractData()', ->

        it 'should extract plain data from an entity', ->
            entity =
                'PartitionKey': {$: 'Edm.String', _: 'users' }
                'RowKey': {$: 'Edm.String', _: 'me' }
                'Timestamp': {$: 'Edm.DateTime', _: "Sun Jan 25 2015 13:46:21 GMT+0000 (UTC)"}
                'name': {_: 'alexandru topliceanu'},
                '.metadata': { etag: 'W/"datetime\'2015-01-25T13:46:21.561796Z\'"' }

            schema =
                'PartitionKey': {type: 'Edm.String', required: true}
                'RowKey': {type: 'Edm.String', required: true}
                'Timestamp': {type: 'Edm.DateTime'}
                'name': {type: 'Edm.String'}

            expected =
                'PartitionKey': 'users'
                'RowKey': 'me'
                'Timestamp': new Date "Sun Jan 25 2015 13:46:21 GMT+0000 (UTC)"
                'name': 'alexandru topliceanu'

            actual = Model.extractData entity, schema
            chai.assert.deepEqual actual, expected,
                'extract raw data from the serialized response'

    describe '.insert()', ->

        before ->
            # Register properties which act as validation methods.
            schemajs.properties.email = (value) ->
                EMAIL_REGEX = /^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/
                return EMAIL_REGEX.test value
            schemajs.properties.url = (value) ->
                URL_REGEX = /https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{2,256}\.[a-z]{2,6}\b([-a-zA-Z0-9@:%_\+.~#?&//=]*)/
                return URL_REGEX.test value
            # Register a filter which acts as a data modifier.
            schemajs.filters.toHttp = (value) ->
                if (value.indexOf 'http://' isnt 0) or (value.indexOf 'http://' isnt 0)
                    return "http://#{value}"

        after (done) ->
            find =
                PartitionKey: azure.TableUtilities.entityGenerator.String 'u'
                RowKey: azure.TableUtilities.entityGenerator.String 'me'
            @service.deleteEntity @testTableName, find, done

        it 'should persist the model data in azure table', (done) ->


            class User extends Model
                @schema:
                    name: {type: 'Edm.String', required: true, properties: {max: 255}}
                    email: {type: 'Edm.String', required: true, properties: {email: true}}
                    website: {type: 'Edm.String', fitlers: ['toHttp'], properties: {url: true}}
                    age: {type: 'Edm.Int32', filters: ['toInt'], properties: {min: 18, max: 125}}
                    active: {type: 'Edm.Boolean', default: true, filters: ['toBoolean']}

            User.build @testTableName, @service

            user = new User
                PartitionKey: 'u'
                RowKey: 'me'
                name: 'alex'
                email: 'me@site.com'
                age: '28'
                active: 'yes'
            user.insert().then (persisted) ->
                chai.assert.instanceOf persisted, Model,
                    'should return the model instance'
            .then (-> done()), done

    describe '.insertOrReplace()', ->

        after (done) ->
            find =
                PartitionKey: azure.TableUtilities.entityGenerator.String 'u'
                RowKey: azure.TableUtilities.entityGenerator.String 'me'
            @service.deleteEntity @testTableName, find, done

        it 'should replace the model with new data in azure table', (done) ->
            class User extends Model
                @schema:
                    name: {type: 'Edm.String', max: 255}
                    age: {type: 'Edm.Int32'}
                    active: {type: 'Edm.Boolean'}
                    birth: {type: 'Edm.DateTime'}

            User.build @testTableName, @service

            user1 =
                PartitionKey: 'u'
                RowKey: 'me'
                name: 'alexandru topliceanu'
                age: 28
                birth: new Date
            user2 =
                PartitionKey: 'u'
                RowKey: 'me'
                name: 'new name'
                age: 38
                birth: new Date

            Q().then =>
                Q.ninvoke @service, 'insertEntity', @testTableName, (User.prepareEntity user1, User.schema)
            .then =>
                (new User user2).insertOrReplace()
            .then (persisted) =>
                chai.assert.instanceOf persisted, Model,
                    'should return the model instance'

                Q.ninvoke @service, 'retrieveEntity', @testTableName, 'u', 'me'
            .then ([entity, response]) =>
                data = User.extractData entity, User.schema
                chai.assert.equal data.name, user2.name, 'the entity name field was replaced'
                chai.assert.equal data.age, user2.age, 'the entity age field was replaced'
            .then (-> done()), done

    describe '.delete()', ->

        before (done) ->
            Q().then =>
                gen = azure.TableUtilities.entityGenerator
                @me =
                    PartitionKey: gen.String 'u'
                    RowKey: gen.String 'me'
                    name: gen.String 'alex'
                Q.ninvoke @service, 'insertEntity', @testTableName, @me
            .then (-> done()), done

        it 'should remove an existing model from azure tables', (done) ->
            class User extends Model
                @schema:
                    name: {type: 'Edm.String', max: 255}

            User.build @testTableName, @service

            user = new User
                PartitionKey: 'u'
                RowKey: 'me'

            user.delete().then =>
                Q.ninvoke @service, 'retrieveEntity', @testTableName, 'u', 'me'
            .then ->
                chai.ok false, 'should have thrown an error, entity removed'
            , (error) ->
                chai.assert.isDefined error, 'should throuw an error'
            .then (-> done()), done
