module Pallets
  module Backends
    class Redis < Base
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

      def pick_worksh
        # No need for transactions; task info doesn't change and context is warned
        # not to be real time but consistent with the workflow graph
        task_id = redis.brpop('queue')
        raw_task = redis.get("tasks:#{task_id}")
        task = JSON.parse(raw_task)
        raw_context = redis.get("contexts:#{workflow_id}")
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
          redis.set("tasks:#{task['id']}", task)
          redis.set("contexts:#{task['workflow_id']}", context)
          task['next'].each do |next_task_id|
            redis.zincrby("pending_tasks:#{task['workflow_id']}", -1, next_task_id)
          end
          redis.eval(ENQ, ["pending_tasks:#{task['workflow_id']}", "queue"])
        end
      end

      def save(jobs, pending_jobs, context)
        redis.multi do
          jobs.each do |job|
            redis.set("jobs:#{job['id']}", job)
          end
          pending_jobs.each do |pending_job|
            redis.zadd("pending_jobs:#{}", *pending_job)
          end
          redis.set("contexts:#{}", context)
        end
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
