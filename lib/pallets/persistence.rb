module Pallets
  class Persistence
    PICK = <<-LUA
      local work = redis.call("BRPOP", KEYS[1])
      local workflow_id, task_id = string.match(work, "(.*)%-(.*)")
      return {
        redis.call("GET", "workflow:" .. workflow_id .. ":tasks:" .. task_id),
        redis.call("GET", "workflow:" .. workflow_id .. ":context")
      }
    LUA

    SAVE = <<-LUA
      redis.call("SET", "workflow:" .. KEYS[1] .. ":tasks:" .. task_id, ARGV[1])
      redis.call("SET", "workflow:" .. KEYS[1] .. ":context", ARGV[2])
    LUA

    ENQ = <<-LUA
      local work = redis.call("ZRANGEBYSCORE", KEYS[1], 0, 0)
      redis.call("LPUSH", "queue", unpack(work))
      redis.call("ZREM", KEYS[1], unpack(work))
    LUA

    def pick_work
      # Returns task and context
      response = Pallets.redis.eval(PICK, ['queue'])
      JSON.parse(response[0]), JSON.parse(response[1])
    end

    def save_work(workflow_id, task, context)
      # Persists task and context
      # Deincrements following tasks
      # Pops and pushes tasks with 0
      Pallets.redis.eval(SAVE, [workflow_id], [task, context])

      redis.multi do
        redis.set("workflow:#{workflow_id}:tasks:#{task_id}", task)
        redis.set("workflow:#{workflow_id}:context", context)
        task['next'].each do |next_task_id|
          redis.zincrby("workflow:#{workflow_id}:priority", -1, next_task_id)
        end
        redis.eval(ENQ, ["workflow:#{workflow_id}:priority"])
      end
    end
  end
end
