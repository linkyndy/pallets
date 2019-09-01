module Pallets
  class Workflow
    extend DSL::Workflow

    attr_reader :context

    def initialize(context_hash = {})
      @id = nil
      # Passed in context hash needs to be buffered
      @context = Context.new.merge!(context_hash)
    end

    def run
      raise WorkflowError, "#{self.class.name} has no tasks. Workflows "\
                           "must contain at least one task" if self.class.graph.empty?

      backend.run_workflow(id, jobs_with_order, serializer.dump_context(context.buffer))
      id
    end

    def id
      @id ||= "P#{Pallets::Util.generate_id(self.class.name)}".upcase
    end

    private

    def jobs_with_order
      self.class.graph.sorted_with_order.map do |task_alias, order|
        job = serializer.dump(construct_job(task_alias))
        [order, job]
      end
    end

    def construct_job(task_alias)
      Hash[self.class.task_config[task_alias]].tap do |job|
        job['wfid'] = id
        job['workflow_class'] = self.class.name
        job['jid'] = "J#{Pallets::Util.generate_id(job['task_class'])}".upcase
        job['created_at'] = Time.now.to_f
      end
    end

    def backend
      Pallets.backend
    end

    def serializer
      Pallets.serializer
    end

    def self.task_config
      @task_config ||= {}
    end

    def self.graph
      @graph ||= Graph.new
    end
  end
end
