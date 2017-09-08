module Pallets
  module Backends
    class Redis < Base
      def initialize(workflow_id)
        @workflow_id = workflow_id
        @queue_key = "pallets:workflow:#{workflow_id}:queue"
        @pending_key = "pallets:workflow:#{workflow_id}:pending"
        @context_key = "pallets:workflow:#{workflow_id}:context"
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
        redis.call("ZREM", KEYS[1], unpack(work))
      LUA

      DECR = <<-LUA
        local all_pending = redis.call("ZRANGE", KEYS[1], 0, -1)
        for score, task in pairs(all_pending) do
          redis.call("ZINCRBY", KEYS[1], -1, task)
        end
      LUA

      def pick_work
        # No need for transactions; task info doesn't change and context is warned
        # not to be real time but consistent with the workflow graph
        raw_task = redis.brpop(@queue_key)
        task = JSON.parse(raw_task)
        raw_context = redis.get(@context_key)
        context = JSON.parse(raw_context)
        # Returns task and context
        # response = Pallets.redis.eval(PICK, ['queue'])
        # JSON.parse(response[0]), JSON.parse(response[1])
        task, context
      end

      def save_work(task, context)
        # Persists task and context
        # Deincrements following tasks
        # Pops and pushes tasks with 0
        # Pallets.redis.eval(SAVE, [workflow_id], [task, context])

        redis.multi do
          # redis.set("tasks:#{task['id']}", task)
          redis.set(@context_key, context)
          redis.eval(DECR, [@pending_key])
          redis.eval(ENQ, [@pending_key, @queue_key])
        end
      end

      def save_workflow(tasks, context)
        redis.multi do
          # tasks is [[1, Task], [2, Task], [2, Task]]
          redis.zadd(@pending_key, tasks)
          redis.set(@context_key, context)
        end
      end

      # enqueues all tasks that have the count 0
      def enqueue_pending
        redis.eval(ENQ, [@pending_key, @queue_key])
      end

      def create_job(job, dependency_count)
        jid = job['id']
        redis.multi do
          jobs.each do |job|
            redis.set("jobs:#{jid}", job)
          end
          pending_jobs.each do |pending_job|
            redis.zadd("pending_jobs:#{}", dependency_count, jid)
          end
          redis.set("contexts:#{}", context)
        end
      end
    end
  end
end
