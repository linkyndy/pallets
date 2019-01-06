require 'redis'

module Pallets
  module Backends
    class Redis < Base
      def initialize(namespace:, blocking_timeout:, job_timeout:, pool_size:, **options)
        @namespace = namespace
        @blocking_timeout = blocking_timeout
        @job_timeout = job_timeout
        @pool = Pallets::Pool.new(pool_size) { ::Redis.new(options) }

        @queue_key = "#{namespace}:queue"
        @reliability_queue_key = "#{namespace}:reliability-queue"
        @reliability_set_key = "#{namespace}:reliability-set"
        @retry_set_key = "#{namespace}:retry-set"
        @fail_set_key = "#{namespace}:fail-set"
        @workflow_key = "#{namespace}:workflows:%s"
        @context_key = "#{namespace}:contexts:%s"
        @counter_key = "#{namespace}:counters:%s"

        register_scripts
      end

      def pick
        job = @pool.execute do |client|
          client.brpoplpush(@queue_key, @reliability_queue_key, timeout: @blocking_timeout)
        end
        if job
          # We store the job's timeout so we know when to retry jobs that are
          # still on the reliability queue. We do this separately since there is
          # no other way to atomically BRPOPLPUSH from the main queue to a
          # sorted set
          @pool.execute do |client|
            client.zadd(@reliability_set_key, Time.now.to_f + @job_timeout, job)
          end
        end
        job
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
            [@workflow_key % workflow_id, @queue_key, @reliability_queue_key, @reliability_set_key, @context_key % workflow_id, @counter_key % workflow_id],
            # [job, context_log_item]
            context_buffer.to_a << job
          )
        end
      end

      def discard(job)
        @pool.execute do |client|
          client.eval(
            @scripts['discard'],
            [@reliability_queue_key, @reliability_set_key],
            [job]
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

      def give_up(job, old_job, at)
        @pool.execute do |client|
          client.eval(
            @scripts['give_up'],
            [@fail_set_key, @reliability_queue_key, @reliability_set_key],
            [at, job, old_job]
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

      def run_workflow(workflow_id, jobs_with_order, context)
        @pool.execute do |client|
          client.eval(
            @scripts['run_workflow'],
            [@workflow_key % workflow_id, @queue_key, @context_key % workflow_id, @counter_key % workflow_id],
            jobs_with_order << jobs_with_order.size
          )
          client.hmset(@context_key % workflow_id, *context.to_a)
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
