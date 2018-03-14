module Pallets
  class Configuration
    # TODO: split these and document them
    attr_accessor :backend, :backend_args, :blocking_timeout, :namespace, :serializer

    def initialize
      @backend = :redis
      @backend_args = {}
      @blocking_timeout = 5
      @namespace = 'pallets'
      @serializer = :json
    end
  end
end
