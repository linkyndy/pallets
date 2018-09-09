require "pallets/version"

require 'pallets/backends/base'
require 'pallets/backends/redis'
require 'pallets/configuration'
require 'pallets/dsl/workflow'
require 'pallets/errors'
require 'pallets/graph'
require 'pallets/manager'
require 'pallets/pool'
require 'pallets/scheduler'
require 'pallets/serializers/base'
require 'pallets/serializers/json'
require 'pallets/task'
require 'pallets/worker'
require 'pallets/workflow'

# TODO: this needs to be removed!
require 'active_support/inflector'
require 'pry-byebug'
require 'logger'

module Pallets
  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.configure
    yield configuration
  end

  def self.backend
    @backend ||= begin
      cls = "Pallets::Backends::#{configuration.backend.capitalize}".constantize
      cls.new(
        namespace: configuration.namespace,
        blocking_timeout: configuration.blocking_timeout,
        job_timeout: configuration.job_timeout,
        pool_size: configuration.pool_size,
        **configuration.backend_args
      )
    end
  end

  def self.serializer
    @serializer ||= begin
      cls = "Pallets::Serializers::#{configuration.serializer.capitalize}".constantize
      cls.new
    end
  end

  def self.logger
    @logger ||= Logger.new(STDOUT)
  end
end
