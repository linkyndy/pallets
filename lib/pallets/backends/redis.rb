require 'redis'

module Pallets
  module Backends
    class Redis < Base
      QUEUE_KEY = 'queue'
      RELIABILITY_QUEUE_KEY = 'reliability-queue'
      RELIABILITY_SET_KEY = 'reliability-set'
      RETRY_SET_KEY = 'retry-set'
      GIVEN_UP_SET_KEY = 'given-up-set'
      WORKFLOW_KEY = 'workflows:%s'
      CONTEXT_KEY = 'contexts:%s'
      ETA_KEY = 'etas:%s'

      def initialize(blocking_timeout:, failed_job_lifespan:, job_timeout:, pool_size:, **options)
        @blocking_timeout = blocking_timeout
        @failed_job_lifespan = failed_job_lifespan
        @job_timeout = job_timeout
        @pool = Pallets::Pool.new(pool_size) { ::Redis.new(options) }

        register_scripts
      end

      def pick
        @pool.execute do |client|
          job = client.brpoplpush(QUEUE_KEY, RELIABILITY_QUEUE_KEY, timeout: @blocking_timeout)
          if job
            # We store the job's timeout so we know when to retry jobs that are
            # still on the reliability queue. We do this separately since there is
            # no other way to atomically BRPOPLPUSH from the main queue to a
            # sorted set
            client.zadd(RELIABILITY_SET_KEY, Time.now.to_f + @job_timeout, job)
          end
          job
        end
      end

      def get_context(workflow_id)
        @pool.execute do |client|
          client.hgetall(CONTEXT_KEY % workflow_id)
        end
      end

      def save(workflow_id, job, context_buffer)
        @pool.execute do |client|
          client.eval(
            @scripts['save'],
            [WORKFLOW_KEY % workflow_id, QUEUE_KEY, RELIABILITY_QUEUE_KEY, RELIABILITY_SET_KEY, CONTEXT_KEY % workflow_id, ETA_KEY % workflow_id],
            context_buffer.to_a << job
          )
        end
      end

      def retry(job, old_job, at)
        @pool.execute do |client|
          client.eval(
            @scripts['retry'],
            [RETRY_SET_KEY, RELIABILITY_QUEUE_KEY, RELIABILITY_SET_KEY],
            [at, job, old_job]
          )
        end
      end

      def give_up(job, old_job)
        @pool.execute do |client|
          client.eval(
            @scripts['give_up'],
            [GIVEN_UP_SET_KEY, RELIABILITY_QUEUE_KEY, RELIABILITY_SET_KEY],
            [Time.now.to_f, job, old_job, Time.now.to_f - @failed_job_lifespan]
          )
        end
      end

      def reschedule_all(earlier_than)
        @pool.execute do |client|
          client.eval(
            @scripts['reschedule_all'],
            [RELIABILITY_SET_KEY, RELIABILITY_QUEUE_KEY, RETRY_SET_KEY, QUEUE_KEY],
            [earlier_than]
          )
        end
      end

      def run_workflow(workflow_id, jobs_with_order, context_buffer)
        @pool.execute do |client|
          client.multi do
            client.eval(
              @scripts['run_workflow'],
              [WORKFLOW_KEY % workflow_id, QUEUE_KEY, ETA_KEY % workflow_id],
              jobs_with_order
            )
            client.hmset(CONTEXT_KEY % workflow_id, *context_buffer.to_a) unless context_buffer.empty?
          end
        end
      end

      private

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
