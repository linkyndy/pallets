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
require 'pallets/util'
require 'pallets/worker'
require 'pallets/workflow'

require 'logger'
require 'securerandom'

module Pallets
  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.configure
    yield configuration
  end

  def self.backend
    @backend ||= begin
      cls = Pallets::Util.constantize("Pallets::Backends::#{configuration.backend.capitalize}")
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
      cls = Pallets::Util.constantize("Pallets::Serializers::#{configuration.serializer.capitalize}")
      cls.new
    end
  end

  def self.logger
    @logger ||= Logger.new(STDOUT)
  end
end
