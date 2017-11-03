module Pallets
  module Backends
    class Redis < Base
      attr_reader :redis

      def initialize
        # @workflow_id = workflow_id
        # TODO: use Pallets.configuration.redis_namespace
        @queue_key = "pallets:queue"
        @jobs_key = "pallets:workflow:%s:jobs"
        @context_key = "pallets:workflow:%s:context"
        @redis = @client = ::Redis.new
      end
      # PICK = <<-LUA
      #   local work = redis.call("BRPOP", KEYS[1])
      #   local workflow_id, task_id = string.match(work, "(.*)%-(.*)")
      #   return {
      #     redis.call("GET", "workflow:" .. workflow_id .. ":tasks:" .. task_id),
      #     redis.call("GET", "workflow:" .. workflow_id .. ":context")
      #   }
      # LUA

      # SAVE = <<-LUA
      #   redis.call("SET", "workflow:" .. KEYS[1] .. ":tasks:" .. task_id, ARGV[1])
      #   redis.call("SET", "workflow:" .. KEYS[1] .. ":context", ARGV[2])
      # LUA

      ENQ = <<-LUA
        local work = redis.call("ZRANGEBYSCORE", KEYS[1], 0, 0)
        redis.call("LPUSH", KEYS[2], unpack(work))
      LUA
      # redis.call("ZREM", KEYS[1], unpack(work)) -- keep everything for status/debug

      DECR = <<-LUA
        local all_pending = redis.call("ZRANGE", KEYS[1], 0, -1)
        for score, task in pairs(all_pending) do
          redis.call("ZINCRBY", KEYS[1], -1, task)
        end
      LUA

      def pick_work
        puts '[backend] pick work'
        # No need for transactions; job info doesn't change and context is warned
        # not to be real time but consistent with the workflow graph
        job = redis.brpop(@queue_key)
        # job = JSON.parse(raw_job)
        context = redis.get(@context_key % job['wfid'])
        # context = JSON.parse(raw_context)
        # Returns job and context
        # response = Pallets.redis.eval(PICK, ['queue'])
        # JSON.parse(response[0]), JSON.parse(response[1])
        [job, context]
      end

      def save_work(job, context)
        puts '[backend] save work'
        # Persists job and context
        # Decrements all jobs
        # Pops and pushes jobs with 0
        # Pallets.redis.eval(SAVE, [workflow_id], [task, context])

        redis.multi do
          # redis.set("tasks:#{task['id']}", task)
          redis.set(@context_key % job['wfid'], context)
          redis.eval(DECR, [@jobs_key % job['wfid']])
          redis.eval(ENQ, [@jobs_key % job['wfid'], @queue_key])
        end
      end

      def start_workflow(wfid, jobs, context)
        puts '[backend] start_workflow'

        redis.multi do
          # jobs is [[1, Job], [2, Job], [2, Job]]
          redis.zadd(@jobs_key % wfid, jobs)
          redis.set(@context_key % wfid, context)
          # also prepare jobs to be picked up by workers
          redis.eval(ENQ, [@jobs_key % wfid, @queue_key])
        end
      end

      # enqueues all tasks that have the count 0
      # def enqueue_pending
      #   redis.eval(ENQ, [@jobs_key, @queue_key])
      # end

      # def create_job(job, dependency_count)
      #   jid = job['id']
      #   redis.multi do
      #     jobs.each do |job|
      #       redis.set("jobs:#{jid}", job)
      #     end
      #     pending_jobs.each do |pending_job|
      #       redis.zadd("pending_jobs:#{}", dependency_count, jid)
      #     end
      #     redis.set("contexts:#{}", context)
      #   end
      # end
    end
  end
end
