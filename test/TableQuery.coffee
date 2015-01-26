azure = require 'azure-storage'
chai = require 'chai'

TableQuery = require '../src/TableQuery'


describe 'TableQuery', ->

    describe '.constructor()', ->

        it 'should create a new TableQuery', ->
            query = new TableQuery
            query.top(5)
                .select('firstName', 'lastName', 'age')
                .where('PartitionKey eq ?', '123')

            chai.assert.instanceOf query, azure.TableQuery,
                'should be an instance of TableQuery'
