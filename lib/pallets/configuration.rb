module Pallets
  class Configuration
    # TODO: split these and document them
    attr_accessor :backend, :backend_args, :blocking_timeout, :job_timeout, :max_failures, :namespace, :pool_size, :serializer

    def initialize
      @backend = :redis
      @backend_args = {}
      @blocking_timeout = 5
      @job_timeout = 1800 # 30 minutes
      @max_failures = 3
      @namespace = 'pallets'
      @pool_size = 5
      @serializer = :json
    end
  end
end
