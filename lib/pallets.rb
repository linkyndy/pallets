require "pallets/version"
require 'pallets/dsl/workflow'

require 'pallets/backends/base'
require 'pallets/configuration'
require 'pallets/errors'
# require 'pallets/backends/redis'
require 'pallets/graph'
require 'pallets/manager'
# require 'pallets/runner'
# require 'pallets/storage'
require 'pallets/pool'
require 'pallets/serializers/base'
# require 'pallets/serializers/json'
require 'pallets/task'
require 'pallets/worker'
require 'pallets/workflow'

# TODO: this needs to be removed!
require 'active_support/inflector'
require 'pry-byebug'
require 'logger'

require 'json'

# Pallets.configure do |config|
#   config.backend = :redis
#   config.serializer = :json
#   config.redis_namespace = 'pallets'
# end

module Pallets
  # Your code goes here...

  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.configure
    yield configuration
  end

  def self.backend
    @backend ||= begin
      require "pallets/backends/#{configuration.backend}"
      cls = "Pallets::Backends::#{configuration.backend.capitalize}".constantize
      cls.new(namespace: configuration.namespace, blocking_timeout: configuration.blocking_timeout, pool_size: configuration.pool_size, **configuration.backend_args)
    end
  end

  def self.serializer
    @serializer ||= begin
      require "pallets/serializers/#{configuration.serializer}"
      cls = "Pallets::Serializers::#{configuration.serializer.capitalize}".constantize
      cls.new
    end
  end

  def self.logger
    @logger ||= Logger.new(STDOUT)
  end

  def self.generate_id(string, prefix='')
    initials = string.gsub(/[^A-Z]+([A-Z])/, '\1')[0,3]
    random = SecureRandom.hex(3)
    "#{prefix}#{initials}#{random}".upcase
  end
end
