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

    attr_reader :id, :context

    def initialize(context = {})
      @id = nil
      @context = context
    end

    def start
      @id ||= Pallets.generate_id(self.class.name, 'W')
      backend.start_workflow(id, jobs_with_dependencies)
    end

    private

    def jobs_with_dependencies
      self.class.graph.sort_by_dependency_count.map do |dependency_count, node|
        [dependency_count, serializer.dump(job_hash(node))]
      end
    end

    def job_hash(task_class)
      {
        'class_name' => task_class.to_s.camelize,
        'wfid'       => id,
        'context'    => context,
        'created_at' => Time.now.to_f
      }
    end

    def backend
      Pallets.backend
    end

    def serializer
      Pallets.serializer
    end

    def self.graph
      @graph ||= Graph.new
    end
  end
end
