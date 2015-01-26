# This example explains how to define validation rules for your models
# by extending schemajs.
#
# Stand exposes an instance of schemajs in `stand.schemajs`, so that you
# can easily add your own types, filters, properties and defaults.
# In fact `stand` adds it's own OData types.
#
# A note of warning, don't use your own types! type information is used
# to serialize data to the azure tables endpoint.
# See http://www.odata.org/documentation/odata-version-2-0/overview/ for
# more information on data types.
#
# For more information see https://github.com/eleith/schemajs
#
#

stand = require 'stand'


class User extends stand.Model
    @schema:
        name: {type: 'Edm.String', required: true, properties: {max: 255}}
        email: {type: 'Edm.String', required: true, properties: {email: true}}
        website: {type: 'Edm.String', fitlers: ['toHttp'], properties: {url: true}}
        age: {type: 'Edm.Int32', filters: ['toInt'], properties: {min: 18, max: 125}}
        active: {type: 'Edm.Boolean', default: true, filters: ['toBoolean']}


# Initialize the table service an register the User model. This will make
# sure the 'user' table exists and is ready for usage.
service = new stand.TableService 'ACCOUNT-NAME', 'ACCESS-KEY'
service.register 'user', User


# Register properties, which act like validation rules, returning Boolean,
# true if the value passes validation.

stand.schemajs.properties.email = (value) ->
    EMAIL_REGEX = /^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/
    return EMAIL_REGEX.test value

stand.schemajs.properties.url = (value) ->
    URL_REGEX = /https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{2,256}\.[a-z]{2,6}\b([-a-zA-Z0-9@:%_\+.~#?&//=]*)/
    return URL_REGEX.test value

# Register filters, which act as modifiers to the data. In this case, the
# `toHttp` filter will add http:// in front of the url if does not exist already.

stand.schemajs.filters.toHttp = (value) ->
    if (value.indexOf 'http://' isnt 0) or (value.indexOf 'http://' isnt 0)
        return "http://#{value}"

# Create a new user
user = new User
    PartitionKey: 'u'
    RowKey: 'me'
    name: 'alex'
    email: 'alex@me.com'
    website: 'http://alex.com' # http:// will be added to this website.
    age: '28' # string will be turned into a number.
    active: 'yes' # this will be turned into a boolean.

# Store the user document by using insertOrReplace(). This will first check if
# the document already exists (with the same PartitionKey/RowKey) and if it
# does, simply replace it with this one.
user.insertOrReplace().then ->
    console.log 'successfully stored the new user'

    # `retrieve()` accepts a PartitionKey and a RowKey and returns a promise
    # which resolves to the retrieved model.
    User.retrieve('u', 'me').then (user) ->
        console.log 'The new user is persisted', user.data
.fail (error) ->
    console.log 'Failed to execute operations', error
