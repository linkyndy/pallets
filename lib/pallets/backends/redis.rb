require 'redis'

module Pallets
  module Backends
    class Redis < Base
      def initialize(namespace:, blocking_timeout:, pool_size:, **options)
        @namespace = namespace
        @blocking_timeout = blocking_timeout
        @pool = Pallets::Pool.new(size: pool_size) { ::Redis.new(options) }

        register_scripts
      end

      def pick_work id
        Pallets.logger.info "[backend #{id}] waiting for work"
        job = @pool.execute { |client| client.brpoplpush(queue_key, reliability_queue_key, timeout: blocking_timeout) }
        if job
          Pallets.logger.info "[backend #{id}] picked work"
        else
          Pallets.logger.info "[backend #{id}] picked nothing"
        end
        job
      end

      def put_back_work(job)
        # TODO: implement retry queue; zset with timestamp as score and job as
        #       member
        puts '[backend] putting back work'
        @pool.execute { |client| client.rpush(queue_key, job) }
        puts '[backend] work put back'
      end

      def save_work(wfid, job, id)
        Pallets.logger.info "[backend #{id}] save work"
        @pool.execute { |client| client.eval(
          @scripts['save_work'],
          [workflow_key(wfid), queue_key, reliability_queue_key],
          [job]
        ) }
        Pallets.logger.info "[backend #{id}] work saved"
      end

      def start_workflow(wfid, jobs)
        puts '[backend] start_workflow'

        # jobs is [[1, Job], [2, Job], [2, Job]]
        @pool.execute { |client| client.eval(
          @scripts['start_workflow'],
          [workflow_key(wfid), queue_key],
          jobs
        ) }
      end

      private

      attr_reader :namespace, :blocking_timeout

      def queue_key
        "#{namespace}:queue"
      end

      def reliability_queue_key
        "#{namespace}:reliability-queue"
      end

      def workflow_key(wfid)
        "#{namespace}:workflows:#{wfid}"
      end

      def register_scripts
        @scripts ||= Dir["#{__dir__}/scripts/*.lua"].map do |file|
          name = File.basename(file, '.lua')
          script = File.read(file)
          [name, script]
        end.to_h
      end
    end
  end
end
