require 'redis'

module Pallets
  module Backends
    class Redis < Base
      def initialize(namespace:, blocking_timeout:, failed_job_lifespan:, job_timeout:, pool_size:, **options)
        @namespace = namespace
        @blocking_timeout = blocking_timeout
        @failed_job_lifespan = failed_job_lifespan
        @job_timeout = job_timeout
        @pool = Pallets::Pool.new(pool_size) { ::Redis.new(options) }

        @queue_key = "#{namespace}:queue"
        @reliability_queue_key = "#{namespace}:reliability-queue"
        @reliability_set_key = "#{namespace}:reliability-set"
        @retry_set_key = "#{namespace}:retry-set"
        @given_up_set_key = "#{namespace}:given-up-set"
        @workflow_key = "#{namespace}:workflows:%s"
        @context_key = "#{namespace}:contexts:%s"
        @eta_key = "#{namespace}:etas:%s"

        register_scripts
      end

      def pick
        @pool.execute do |client|
          job = client.brpoplpush(@queue_key, @reliability_queue_key, timeout: @blocking_timeout)
          if job
            # We store the job's timeout so we know when to retry jobs that are
            # still on the reliability queue. We do this separately since there is
            # no other way to atomically BRPOPLPUSH from the main queue to a
            # sorted set
            client.zadd(@reliability_set_key, Time.now.to_f + @job_timeout, job)
          end
          job
        end
      end

      def get_context(workflow_id)
        @pool.execute do |client|
          client.hgetall(@context_key % workflow_id)
        end
      end

      def save(workflow_id, job, context_buffer)
        @pool.execute do |client|
          client.eval(
            @scripts['save'],
            [@workflow_key % workflow_id, @queue_key, @reliability_queue_key, @reliability_set_key, @context_key % workflow_id, @eta_key % workflow_id],
            context_buffer.to_a << job
          )
        end
      end

      def retry(job, old_job, at)
        @pool.execute do |client|
          client.eval(
            @scripts['retry'],
            [@retry_set_key, @reliability_queue_key, @reliability_set_key],
            [at, job, old_job]
          )
        end
      end

      def give_up(job, old_job)
        @pool.execute do |client|
          client.eval(
            @scripts['give_up'],
            [@given_up_set_key, @reliability_queue_key, @reliability_set_key],
            [Time.now.to_f, job, old_job, Time.now.to_f - @failed_job_lifespan]
          )
        end
      end

      def reschedule_all(earlier_than)
        @pool.execute do |client|
          client.eval(
            @scripts['reschedule_all'],
            [@reliability_set_key, @reliability_queue_key, @retry_set_key, @queue_key],
            [earlier_than]
          )
        end
      end

      def run_workflow(workflow_id, jobs_with_order, context_buffer)
        @pool.execute do |client|
          client.multi do
            client.eval(
              @scripts['run_workflow'],
              [@workflow_key % workflow_id, @queue_key, @eta_key % workflow_id],
              jobs_with_order
            )
            client.hmset(@context_key % workflow_id, *context_buffer.to_a) unless context_buffer.empty?
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
