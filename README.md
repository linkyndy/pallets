# Pallets

[![Build Status](https://travis-ci.com/linkyndy/pallets.svg?branch=master)](https://travis-ci.com/linkyndy/pallets)

Toy workflow engine, written in Ruby

## It is plain simple!

```ruby
# my_workflow.rb
require 'pallets'

class MyWorkflow < Pallets::Workflow
  task :foo
  task :bar => :foo
  task :baz => :foo
  task :qux => [:bar, :baz]
end

class Foo < Pallets::Task
  def run
    puts 'I love Pallets! <3'
  end
end
# [other task definitions are ommited, for now]

MyWorkflow.new.run
```

That's basically it! Curious for more? Read on or [check the examples](examples/)!

> Don't forget to run pallets, so it can process your tasks: `bundle exec pallets -r ./my_workflow`

## Features

* faaast!
* reliable
* retries failed tasks
* Redis backend out of the box
* JSON and msgpack serializers out of the box
* beautiful DSL
* convention over configuration
* thoroughly tested

## Installation

```
# Gemfile
gem 'pallets'

# or

gem install pallets
```

## Configuration

```ruby
Pallets.configure do |c|
  # How many workers to process incoming jobs?
  c.concurrency = 2

  c.backend = :redis
  c.serializer = :json

  c.backend_args = { db: 1 }

  # What's the maximum allowed time to process a job?
  c.job_timeout = 1800
  # How many times should a job be retried?
  c.max_failures = 3
end
```

For the complete set of options, see [pallets/configuration.rb](lib/pallets/configuration.rb)

## Motivation

The main reason for Pallet's existence was the need of a fast, simple and reliable workflow engine, one that is easily extensible with various backends and serializer, one that does not lose your data and one that is intelligent enough to concurrently schedule a workflow's tasks.

## Status

Pallets is under active development and it is not _yet_ production-ready.

## How to contribute?

Any contribution is **highly** appreciated! See [CONTRIBUTING.md](CONTRIBUTING.md) for more details.

## License

See [LICENSE](LICENSE)
