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

    # Custom logger used throughout Pallets
    attr_writer :logger

    # Maximum number of failures allowed per job. Can also be configured on a
    # per task basis
    attr_accessor :max_failures

    # Number of connections to the backend
    attr_writer :pool_size

    # Serializer used for jobs
    attr_accessor :serializer

    # Middleware used to wrap job execution with custom logic. Acts like a stack
    # and accepts callable objects (lambdas, procs, objects that respond to call)
    # that take three arguments: the worker handling the job, the job hash and
    # the context
    #
    # A minimal example of a middleware is:
    #   ->(worker, job, context, &b) { puts 'Hello World!'; b.call }
    attr_reader :middleware

    def initialize
      @backend = :redis
      @backend_args = {}
      @blocking_timeout = 5
      @concurrency = 2
      @failed_job_lifespan = 7_776_000 # 3 months
      @job_timeout = 1_800 # 30 minutes
      @max_failures = 3
      @serializer = :json
      @middleware = default_middleware
    end

    def logger
      @logger || Pallets::Logger.new(STDOUT,
        level: Pallets::Logger::INFO,
        formatter: Pallets::Logger::Formatters::Pretty.new
      )
    end

    def pool_size
      @pool_size || @concurrency + 1
    end

    def default_middleware
      Middleware::Stack[
        Middleware::JobLogger
      ]
    end
  end
end
