# Pallets

[![Build Status](https://travis-ci.com/linkyndy/pallets.svg?branch=master)](https://travis-ci.com/linkyndy/pallets)

Toy workflow engine, written in Ruby

## It is plain simple!

```ruby
# my_workflow.rb
require 'pallets'

class MyWorkflow < Pallets::Workflow
  task Foo
  task Bar => Foo
  task Baz => Foo
  task Qux => [Bar, Baz]
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

## Cookbook

### DSL

Pallets is designed for developers' happiness. Its DSL aims to be as beautiful
and readable as possible, while still enabling complex scenarios to be performed.

```ruby
# All workflows must subclass Pallets::Workflow
class WashClothes < Pallets::Workflow
  # The simplest task
  task BuyDetergent

  # Another task; since it has no dependencies, it will be executed in parallel
  # with BuyDetergent
  # TIP: Use a String argument when task is not _yet_ loaded
  task 'BuySoftener'

  # We're not doing it in real life, but we use it to showcase our first dependency!
  task DilluteDetergent => BuyDetergent

  # We're getting more complex here! This is the alternate way of defining
  # dependencies (which can be several, by the way!). Choose the style that fits
  # you best
  task TurnOnWashingMachine, depends_on: [BuyDetergent, 'BuySoftener']

  # Specify how many times a task is allowed to fail. If max_failures is reached
  # the task is given up
  task SelectProgram => TurnOnWashingMachine, max_failures: 2
end

# Every task must be a subclass of Pallets::Task
class BuyDetergent < Pallets::Task
  # Tasks must implement this method; here you can define whatever rocket science
  # your task needs to perform!
  def run
    # ...do whatever...
  end
end

# We're omitting the other task definitions for now; you shouldn't!
```

## Motivation

The main reason for Pallet's existence was the need of a fast, simple and reliable workflow engine, one that is easily extensible with various backends and serializer, one that does not lose your data and one that is intelligent enough to concurrently schedule a workflow's tasks.

## Status

Pallets is under active development and it is not _yet_ production-ready.

## How to contribute?

Any contribution is **highly** appreciated! See [CONTRIBUTING.md](CONTRIBUTING.md) for more details.

## License

See [LICENSE](LICENSE)
