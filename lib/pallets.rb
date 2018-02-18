require "pallets/version"
require 'pallets/dsl/workflow'

require 'pallets/backends/base'
require 'pallets/backends/redis'
require 'pallets/graph'
require 'pallets/manager'
# require 'pallets/runner'
# require 'pallets/storage'
require 'pallets/serializers/base'
require 'pallets/serializers/json'
require 'pallets/task'
require 'pallets/worker'
require 'pallets/workflow'

# TODO: this needs to be removed!
require 'active_support/inflector'
require 'pry-byebug'
require 'logger'
require 'redis'
require 'json'

# Pallets.configure do |config|
#   config.backend = :redis
#   config.serializer = :json
#   config.redis_namespace = 'pallets'
# end

module Pallets
  # Your code goes here...

  class << self
    attr_accessor :configuration
  end

  def self.configure
    self.configuration ||= Configuration.new
    yield configuration
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
