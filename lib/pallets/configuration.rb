module Pallets
  module Configuration
    attr_accessor :backend, :serializer, :redis_namespace

    def initialize
      @backend = :redis
      @serializer = :json
      # TODO: move redis somewhere else
      @redis_namespace = 'pallets'
    end
  end
end
