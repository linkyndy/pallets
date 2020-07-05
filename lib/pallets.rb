require "pallets/version"

require 'pallets/backends/base'
require 'pallets/backends/redis'
require 'pallets/configuration'
require 'pallets/context'
require 'pallets/dsl/workflow'
require 'pallets/errors'
require 'pallets/graph'
require 'pallets/logger'
require 'pallets/manager'
require 'pallets/middleware/job_logger'
require 'pallets/middleware/stack'
require 'pallets/pool'
require 'pallets/scheduler'
require 'pallets/serializers/base'
require 'pallets/serializers/json'
require 'pallets/serializers/msgpack'
require 'pallets/task'
require 'pallets/util'
require 'pallets/worker'
require 'pallets/workflow'

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
        blocking_timeout: configuration.blocking_timeout,
        failed_job_lifespan: configuration.failed_job_lifespan,
        failed_job_max_count: configuration.failed_job_max_count,
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

  def self.middleware
    @middleware ||= configuration.middleware
  end

  def self.logger
    @logger ||= Pallets::Logger.new(STDOUT,
      level: Pallets::Logger::INFO,
      formatter: Pallets::Logger::Formatters::Pretty.new
    )
  end
end
