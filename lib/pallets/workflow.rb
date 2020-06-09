module Pallets
  class Workflow
    extend DSL::Workflow

    attr_reader :context

    def self.build(&block)
      Class.new(self).tap do |workflow_class|
        workflow_class.instance_eval(&block)
      end
    end

    def initialize(context_hash = {})
      @id = nil
      # Passed in context hash needs to be buffered
      @context = Context.new.merge!(context_hash)
    end

    def run
      raise WorkflowError, "#{self.class.name} has no tasks. Workflows "\
                           "must contain at least one task" if self.class.graph.empty?

      backend.run_workflow(id, *prepare_jobs, serializer.dump_context(context.buffer))
      id
    end

    def id
      @id ||= "P#{Pallets::Util.generate_id(self.class.name)}".upcase
    end

    private

    def prepare_jobs
      jobs = []
      jobmasks = Hash.new { |h, k| h[k] = [] }
      acc = {}

      self.class.graph.each do |task_alias, dependencies|
        job_hash = construct_job(task_alias)
        acc[task_alias] = job_hash['jid']
        job = serializer.dump(job_hash)

        jobs << [dependencies.size, job]
        dependencies.each { |d| jobmasks[acc[d]] << [-1, job] }
      end

      [jobs, jobmasks]
    end

    def construct_job(task_alias)
      Hash[self.class.task_config[task_alias]].tap do |job|
        job['wfid'] = id
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

    def self.name
      @name ||= super || '<Anonymous>'
    end

    def self.task_config
      @task_config ||= {}
    end

    def self.graph
      @graph ||= Graph.new
    end
  end
end
