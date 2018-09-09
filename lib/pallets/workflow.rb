# class ProcessOrder < Workflow
#   task :buy
#   task :pay => :buy, more_context: { amount: 100 }
#   task :ship, depends_on: :pay
#   task :send_email, depends_on: :pay, retry: 3
#   task :mark_as_complete => [:pay, :send_email]
#   task :done => :mark_as_complete do
#     puts 'I am done!'
#   end
#
#   task :with_condition, if: -> { payload[:arg] == true }
# end
#
# ProcessOrder.new(order_id: 123, method: :visa) # context
#
# class Pay < Task
#   def perform
#     puts context[:buy_sum]
#     context[:pay_sum] = 3
#   end
# end

# workflow = ProcessOrder.new(order_id: 123, method: :visa)
# workflow.start
# => abc123
# workflow.finished?
# => false
# workflow = ProcessOrder.find('abc123')
# workflow.tasks
# => { :buy => :finished, :pay => :running } # :pending, :running, :finished, :failed

# workflow :process_order do
#   task :buy
#   task :pay => :buy
# end
#
# Pallets.workflows(:process_order).first
# Pallets.workflow('abc123')

module Pallets
  class Workflow
    extend DSL::Workflow

    attr_reader :context

    def initialize(context = {})
      @id = nil
      @context = context
    end

    def start
      @running ||= begin
        backend.start_workflow(id, jobs_with_dependencies)
      end
    end

    def id
      @id ||= begin
        initials = self.class.name.gsub(/[^A-Z]+([A-Z])/, '\1')[0,3]
        random = SecureRandom.hex(5)
        "P#{initials}#{random}".upcase
      end
    end

    private

    def jobs_with_dependencies
      self.class.graph.sort_by_dependency_count.map do |dependency_count, task_name|
        [dependency_count, serializer.dump(job_hash(task_name))]
      end
    end

    def job_hash(task_name)
      {
        'class_name' => task_name.to_s.camelize,
        'wfid'       => id,
        'context'    => context,
        'created_at' => Time.now.to_f
      }.merge(self.class.task_config[task_name])
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
