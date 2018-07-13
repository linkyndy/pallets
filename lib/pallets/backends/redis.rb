require 'redis'

module Pallets
  module Backends
    class Redis < Base
      def initialize(namespace:, blocking_timeout:, job_timeout:, pool_size:, **options)
        @namespace = namespace
        @blocking_timeout = blocking_timeout
        @job_timeout = job_timeout
        @pool = Pallets::Pool.new(size: pool_size) { ::Redis.new(options) }

        register_scripts
      end

      def pick_work
        job = @pool.execute do |client|
          client.brpoplpush(queue_key, reliability_queue_key, timeout: @blocking_timeout)
        end
        if job
          # We store the job's timeout so we know when to retry jobs that are
          # still on the reliability queue. We do this separately since there is
          # no other way to atomically BRPOPLPUSH from the main queue to a
          # sorted set
          @pool.execute do |client|
            client.zadd(reliability_set_key, Time.now.to_f + @job_timeout, job)
          end
        end
        job
      end

      def save_work(wfid, job)
        @pool.execute do |client|
          client.eval(
            @scripts['save_work'],
            [workflow_key(wfid), queue_key, reliability_queue_key, reliability_set_key],
            [job]
          )
        end
      end

      def discard(job)
        @pool.execute do |client|
          client.eval(
            @scripts['discard_work'],
            [reliability_queue_key, reliability_set_key],
            [job]
          )
        end
      end

      def retry_work(job, old_job, retry_at)
        @pool.execute do |client|
          client.eval(
            @scripts['retry_work'],
            [retry_queue_key, reliability_queue_key, reliability_set_key],
            [retry_at, job, old_job]
          )
        end
      end

      def kill_work(job, old_job, killed_at)
        @pool.execute do |client|
          client.eval(
            @scripts['kill_work'],
            [failed_queue_key, reliability_queue_key, reliability_set_key],
            [killed_at, job, old_job]
          )
        end
      end

      def reschedule_jobs(earlier_than)
        @pool.execute do |client|
          client.eval(
            @scripts['reschedule_work'],
            [reliability_set_key, reliability_queue_key, retry_queue_key, queue_key],
            [earlier_than]
          )
        end
      end

      def start_workflow(wfid, jobs_with_dependencies)
        @pool.execute do |client|
          client.eval(
            @scripts['start_workflow'],
            [workflow_key(wfid), queue_key],
            jobs_with_dependencies
          )
        end
      end

      private

      def queue_key
        "#{@namespace}:queue"
      end

      def reliability_queue_key
        "#{@namespace}:reliability-queue"
      end

      def reliability_set_key
        "#{@namespace}:reliability-set"
      end

      def retry_queue_key
        "#{@namespace}:retry-queue"
      end

      def failed_queue_key
        "#{@namespace}:failed-queue"
      end

      def workflow_key(wfid)
        "#{@namespace}:workflows:#{wfid}"
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
