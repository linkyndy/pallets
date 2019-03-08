module Pallets
  class Configuration
    # Backend to use for handling workflows
    attr_accessor :backend

    # Arguments used to initialize the backend
    attr_accessor :backend_args

    # Number of seconds to block while waiting for jobs
    attr_accessor :blocking_timeout

    # Number of workers to process jobs
    attr_accessor :concurrency

    # Minimum number of seconds a failed job stays in the given up set. After
    # this period, jobs will be permanently deleted
    attr_accessor :failed_job_lifespan

    # Number of seconds allowed for a job to be processed. If a job exceeds this
    # period, it is considered failed, and scheduled to be processed again
    attr_accessor :job_timeout

    # Maximum number of failures allowed per job. Can also be configured on a
    # per task basis
    attr_accessor :max_failures

    # Number of connections to the backend
    attr_accessor :pool_size

    # Serializer used for jobs
    attr_accessor :serializer

    def initialize
      @backend = :redis
      @backend_args = {}
      @blocking_timeout = 5
      @concurrency = 2
      @failed_job_lifespan = 7_776_000 # 3 months
      @job_timeout = 1_800 # 30 minutes
      @max_failures = 3
      @pool_size = 5
      @serializer = :json
    end
  end
end
