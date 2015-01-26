# Stand


## Gist

**Stand** is a simple Object Document Mapper on top of Azure Table Storage Service.

## Why?

Azure Table Storage sdk for node is really well written and documented. This project should be used along-side the basic driver and attempts to simply add syntactic sugar on top of the existing sdk, eg. simple data modeling, promise-based api, etc.

## Status

[![NPM](https://nodei.co/npm/stand.png?downloads=true&stars=true)](https://nodei.co/npm/stand/)

[![NPM](https://nodei.co/npm-dl/stand.png?months=12)](https://nodei.co/npm-dl/stand/)

| Indicator              |                                                                          |
|:-----------------------|:-------------------------------------------------------------------------|
| documentation          | [topliceanu.github.io/stand](http://topliceanu.github.io/stand) ~~[hosted on coffedoc.info](http://coffeedoc.info/github/topliceanu/stand/master/)~~|
| continuous integration | [![Build Status](https://travis-ci.org/topliceanu/stand.svg?branch=master)](https://travis-ci.org/topliceanu/stand) |
| dependency management  | [![Dependency Status](https://david-dm.org/topliceanu/stand.svg?style=flat)](https://david-dm.org/topliceanu/stand) [![devDependency Status](https://david-dm.org/topliceanu/stand/dev-status.svg?style=flat)](https://david-dm.org/topliceanu/stand#info=devDependencies) |
| code coverage          | [![Coverage Status](https://coveralls.io/repos/topliceanu/stand/badge.svg?branch=master)](https://coveralls.io/r/topliceanu/stand?branch=master) |
| examples               | [/examples](https://github.com/topliceanu/stand/tree/master/examples) |
| development management | [![Stories in Ready](https://badge.waffle.io/topliceanu/stand.svg?label=ready&title=Ready)](http://waffle.io/topliceanu/stand) |
| change log             | [CHANGELOG](https://github.com/topliceanu/stand/blob/master/CHANGELOG.md) [Releases](https://github.com/topliceanu/stand/releases) |

## Features

- Lightweigh wrapper on top of the [official azure storage sdk](https://github.com/Azure/azure-storage-node) with an OOP syntax.
- All methods return promises instead of using the callback pattern.
- Flexible declarative schema DSL using [schemajs](https://github.com/eleith/schemajs) which allows easy configuration of entity data validation, defaults, etc.
- Chaining table query API.

## Install

```shell
npm install stand
```

## Quick Example

```coffeescript
stand = require 'stand'

service = new stand.TableService 'my-storage-account', 'my-long-access-key'

class Url extends stand.Model
    @schema:
        'Url': {type: 'Edm.String', required: true}

service.register 'url', Url

url = new Url
    'PartitionKey': 'u',
    'RowKey': '2EfWx5p', # short hash.
    'Url': 'http://google.com' # original url

url.insert().then ->
    console.log 'successfully inserted the new url'

    Url.find()
        .where('RowKey eq ?', '2EfWx5p')
        .exec().then (urls) ->
            console.log "The expanded url is", (urls[0].get 'Url')
.fail (error) ->
    console.log 'Failed to execute operations', error
```

## More Examples

See more in the `/examples` directory. All examples have instructions on __how to run and test them__.
Examples are written in coffeescript but they should work just as fine in javascript.

- [examples/basic-usage.coffee](https://github.com/topliceanu/stand/blob/master/examples/basic-usage.js) - shows how to define a new model class, create a model, persist it then retrieve it from the tables service.
- [examples/custom-schema.coffee](https://github.com/topliceanu/stand/blob/master/examples/custom-schema.js) - shows how to define a custom schema with default values, modifiers, validation and filtering.

## Contributing

1. Contributions to this project are more than welcomed!
    - Anything from improving docs, code cleanup to advanced functionality is greatly appreciated.
    - Before you start working on an ideea, please open an issue and describe in detail what you want to do and __why it's important__.
    - You will get an answer in max 12h depending on your timezone.
2. Fork the repo!
3. If you use [vagrant](https://www.vagrantup.com/) then simply clone the repo into a folder then issue `$ vagrant up`
    - if you don't use it, please consider learning it, it's easy to install and to get started with.
    - If you don't use it, then you have to:
         - install node.js and all node packages required in development using `$ npm install`
         - For reference, see `./vagrant_boostrap.sh` for bash commands on how to setup all dependencies on a fresh ubuntu 14.04 machine.
    - Run the tests to make sure you have a correct setup: `$ npm run test`
        - setup storage service connection credentials as global env variables: AZURE_STORAGE_ACCOUNT, AZURE_STORAGE_ACCESS_KEY
4. Create a new branch and implement your feature.
 - make sure you add tests for your feature. In the end __all tests have to pass__! To run test suite `$ npm run test`.
    - please note that due to the nature of Azure Table Storage Service, sometimes the endpoints may timeout, which leads to failed tests, so increase test timeout as needed.
 - make sure test coverage does not decrease. Run `$ npm run coverage` to open a browser window with the coverage report.
 - make sure you document your code and generated code looks ok. Run `$ npm run doc` to re-generate the documentation.
 - make sure code is linted (and tests too). Run `$ npm run lint`
 - submit a pull request with your code.
 - hit me up for a code review!
5. Have my kindest thanks for making this project better!


## Licence

(The MIT License)

Copyright (c) 2012 Alexandru Topliceanu (alexandru.topliceanu@gmail.com)

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
