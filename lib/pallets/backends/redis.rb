require 'redis'

module Pallets
  module Backends
    class Redis < Base
      QUEUE_KEY = 'queue'
      RELIABILITY_QUEUE_KEY = 'reliability-queue'
      RELIABILITY_SET_KEY = 'reliability-set'
      RETRY_SET_KEY = 'retry-set'
      GIVEN_UP_SET_KEY = 'given-up-set'
      WORKFLOW_QUEUE_KEY = 'workflow-queue:%s'
      JOBMASKS_KEY = 'jobmasks:%s'
      JOBMASK_KEY = 'jobmask:%s'
      CONTEXT_KEY = 'context:%s'
      REMAINING_KEY = 'remaining:%s'

      def initialize(blocking_timeout:, failed_job_lifespan:, failed_job_max_count:, job_timeout:, pool_size:, **options)
        @blocking_timeout = blocking_timeout
        @failed_job_lifespan = failed_job_lifespan
        @failed_job_max_count = failed_job_max_count
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

      def get_context(wfid)
        @pool.execute do |client|
          client.hgetall(CONTEXT_KEY % wfid)
        end
      end

      def save(wfid, jid, job, context_buffer)
        @pool.execute do |client|
          client.evalsha(
            @scripts['save'],
            [WORKFLOW_QUEUE_KEY % wfid, QUEUE_KEY, RELIABILITY_QUEUE_KEY, RELIABILITY_SET_KEY, CONTEXT_KEY % wfid, REMAINING_KEY % wfid, JOBMASK_KEY % jid, JOBMASKS_KEY % wfid],
            context_buffer.to_a << job
          )
        end
      end

      def retry(job, old_job, at)
        @pool.execute do |client|
          client.evalsha(
            @scripts['retry'],
            [RETRY_SET_KEY, RELIABILITY_QUEUE_KEY, RELIABILITY_SET_KEY],
            [at, job, old_job]
          )
        end
      end

      def discard(job)
        @pool.execute do |client|
          client.evalsha(
            @scripts['discard'],
            [GIVEN_UP_SET_KEY, RELIABILITY_QUEUE_KEY, RELIABILITY_SET_KEY],
            [Time.now.to_f, job, Time.now.to_f - @failed_job_lifespan, @failed_job_max_count]
          )
        end
      end

      def give_up(wfid, job, old_job)
        @pool.execute do |client|
          client.evalsha(
            @scripts['give_up'],
            [GIVEN_UP_SET_KEY, RELIABILITY_QUEUE_KEY, RELIABILITY_SET_KEY, JOBMASKS_KEY % wfid, WORKFLOW_QUEUE_KEY % wfid, REMAINING_KEY % wfid, CONTEXT_KEY % wfid],
            [Time.now.to_f, job, old_job, Time.now.to_f - @failed_job_lifespan, @failed_job_max_count]
          )
        end
      end

      def reschedule_all(earlier_than)
        @pool.execute do |client|
          client.evalsha(
            @scripts['reschedule_all'],
            [RELIABILITY_SET_KEY, RELIABILITY_QUEUE_KEY, RETRY_SET_KEY, QUEUE_KEY],
            [earlier_than]
          )
        end
      end

      def run_workflow(wfid, jobs, jobmasks, context_buffer)
        @pool.execute do |client|
          client.multi do |pipeline|
            jobmasks.each { |jid, jobmask| pipeline.zadd(JOBMASK_KEY % jid, jobmask) }
            pipeline.sadd(JOBMASKS_KEY % wfid, jobmasks.map { |jid, _| JOBMASK_KEY % jid }) unless jobmasks.empty?
            pipeline.evalsha(
              @scripts['run_workflow'],
              [WORKFLOW_QUEUE_KEY % wfid, QUEUE_KEY, REMAINING_KEY % wfid],
              jobs
            )
            pipeline.hmset(CONTEXT_KEY % wfid, *context_buffer.to_a) unless context_buffer.empty?
          end
        end
      end

      private

      def register_scripts
        @scripts ||= @pool.execute do |client|
          Dir["#{__dir__}/scripts/*.lua"].map do |file|
            name = File.basename(file, '.lua')
            script = File.read(file)
            sha = client.script(:load, script)
            [name, sha]
          end.to_h
        end
      end
    end
  end
end
