chai = require 'chai'
Q = require 'q'

Model = require '../src/Model'


describe 'Model', ->
    @timeout 5000

    describe 'class', ->
        # NOTE ! These tests are not well isolated
        # and are not meant to be run individually!

        before ->
            class @User extends Model
                @tableName: 'users'
                @schema:
                    Username: {type: 'string+', required: true}

            class @Event extends Model
                @tableName: 'events'

        it '#build() should correctly set @ready '+
           'after repeated instantiations', (done) ->
            user1 = new @User
            user2 = new @User
            user3 = new @User

            event1 = new @Event
            event2 = new @Event
            event3 = new @Event

            chai.assert.ok Q.isPromise user1.constructor.ready
            chai.assert.ok Q.isPromise user2.constructor.ready
            chai.assert.ok Q.isPromise user3.constructor.ready

            chai.assert.ok Q.isPromise event1.constructor.ready
            chai.assert.ok Q.isPromise event2.constructor.ready
            chai.assert.ok Q.isPromise event3.constructor.ready

            chai.assert.equal user1.constructor.ready, user2.constructor.ready,
                'all instances share the same ready function'

            expectedSchema =
                PartitionKey: {type: 'string+', required: true}
                RowKey: {type: 'string+', required: true}
                Username: {type: 'string+', required: true}
            chai.assert.deepEqual @User.schema, expectedSchema,
                'should have merged the defined schema'

            Q.all([
                user1.constructor.ready
                user2.constructor.ready
                user3.constructor.ready
                event1.constructor.ready
                event2.constructor.ready
                event3.constructor.ready
            ]).then (-> done()), done

        it '#validate() should validate input data', (done) ->
            data =
                PartitionKey: 'admins'
                RowKey: '1'
                Username: 'me'
                Password: 'fake'
            (@User.validate data).then (cleanData) ->
                expectedData =
                    PartitionKey: 'admins'
                    RowKey: '1'
                    Username: 'me'
                chai.assert.deepEqual cleanData, expectedData,
                    'should return clean data'
                chai.assert.isUndefined cleanData.Password,
                    'removes the data not defined in schema'
            .then (-> done()), done

        it '#createTableIfNotExists() should create a named table '+
           'if it does not yet exist or leave it be', (done) ->
            Q.all([
                @User.createTableIfNotExists()
                @Event.createTableIfNotExists()
            ]).then (-> done()), done

        #it '#clearTable() should delete the table then recreate it', (done) ->
        #    @User.clearTable().then ->
        #        Q.delay 1000
        #    .then (-> done()), done

        it '#deleteTable() should remove tables from the service', (done) ->
            Q.all([
                @User.deleteTable()
                @Event.deleteTable()
            ]).then (-> done()), done

    describe 'instance', ->

        before ->
            class @Email extends Model
                @tableName: 'emails'
                @schema:
                    Dest: {type: 'string+'}

        it '.insertOrReplaceEntity() should insert or '+
           'update and retrieve an entity', (done) ->
            data =
                PartitionKey: 'me'
                RowKey: '1'
                Dest: 'other'
            email = new @Email data
            email.insertOrReplaceEntity().then =>
                @Email.queryEntity data.PartitionKey, data.RowKey
            .then ([output, response]) ->
                chai.assert.isTrue response.isSuccessful,
                    'should have successfully retrieved the input data'
                chai.assert.equal output.PartitionKey, data.PartitionKey,
                    'same partition key'
                chai.assert.equal output.RowKey, data.RowKey,
                    'same row key'
                chai.assert.equal output.Dest, data.Dest,
                    'same custom var'
            .then (-> done()), done

        it '.deleteEntity() should remove entity', (done) ->
            data =
                PartitionKey: 'me'
                RowKey: '1'
            email = new @Email data
            email.deleteEntity().then =>
                @Email.queryEntity data.PartitionKey, data.RowKey
            .then ->
                chai.assert.ok false, 'should not get here'
            , (error) ->
                chai.assert.match error.message,
                    /The specified resource does not exist./,
                    'Should return an error'
            .then (-> done()), done

        it '.save() should validate and store the current entity data', (done)->
            data =
                PartitionKey: 'me'
                RowKey: '2'
                Dest: 'someone'
                Unwanted: 'something'
            email = new @Email data
            email.save().then =>
                @Email.queryEntity data.PartitionKey, data.RowKey
            .then ([returnData, response]) ->
                chai.assert.equal returnData.PartitionKey, data.PartitionKey,
                    'correct partition'
                chai.assert.equal returnData.RowKey, data.RowKey,
                    'correct row'
                chai.assert.equal returnData.Dest, data.Dest,
                    'correct custom param'
                chai.assert.isUndefined returnData.Unwanted,
                    'has removed the non-expected key'
            .then (-> done()), done