module Pallets
  module Adapters
    module Registry
      class Redis
        def get_task(unit_of_work)
          workflow_id, task_id = unit_of_work.split('-')
          raw_task = Pallets.redis.get("workflow:#{workflow_id}:tasks:#{task_id}")
          JSON.parse(raw_task)
        end

        def set_task(unit_of_work, task)
          workflow_id, task_id = unit_of_work.split('-')
          raw_task = JSON.generate(task)
          Pallets.redis.set("workflow:#{workflow_id}:tasks:#{task_id}", raw_task)
        end

        def get_context(unit_of_work)
          workflow_id, _ = unit_of_work.split('-')
          raw_context = Pallets.redis.get("workflow:#{workflow_id}:context")
          JSON.parse(raw_context)
        end

        def set_context(unit_of_work, context)
          workflow_id, _ = unit_of_work.split('-')
          raw_context = JSON.generate(context)
          Pallets.redis.set("workflow:#{workflow_id}:context")
        end
      end
    end
  end
end
