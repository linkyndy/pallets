# class ProcessOrder < Workflow
#   task :buy
#   task :pay => :buy, more_context: { amount: 100 }
#   task :ship, depends_on: :pay
#   task :send_email, depends_on: :pay
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
# => { :buy => :finished, :pay => :running }

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
      @jobs = []
      @pending_jobs = []
      @context = context
    end

    def start
      puts 'starting workflow'
      @id = Pallets.generate_id(self.class.name, 'W')
      create_jobs
      save
      # enqueue_initial_jobs
    end

    def create_jobs
      # jobs = []
      # graph.tsort.reverse_each.with_object({}) do |node, jids|
      #   next_jids = graph.children(node).map { |child| jids[child] }
      #   jobs << job = {
      #     'jid' => SecureRandom.hex,
      #     'class' => node.to_s.camelize,
      #     'wfid' => id,
      #     'next_jids' => next_jids,
      #     'dependency_count' => graph.parents(node).size
      #   }
      #   jids[node] = job['jid']
      # end

      # self.class.backend.create_jobs(jobs)

      # graph.tsort.reverse_each do |node|
      #   next_jids = graph.children(node).map { |child_node| @jobs[child_node]['jid'] }
      #   @jobs[node] = {
      #     'jid' => SecureRandom.hex,
      #     'class' => node.to_s.camelize,
      #     'wfid' => id,
      #     'next_jids' => next_jids
      #   }
      #   @pending_jobs << [graph.parents(node).size, @jobs[node]['jid']]
      # end
      #
      # graph.tsort.each do |node|
      #   @jobs[node] = {
      #     'jid' => SecureRandom.hex,
      #     'class' => node.to_s.camelize,
      #     'wfid' => id,
      #     'next_jids' => next_jids
      #   }
      # end

      puts 'creating jobs'
      self.class.graph.sort_by_dependency_count.each do |dependency_count, node|
        jobs << [dependency_count, serializer.dump({
          'jid' => Pallets.generate_id(node.to_s, 'J'),
          'class' => node.to_s.camelize,
          'wfid' => id
        })]
      end
    end

    def save
      puts 'saving workflow'
      backend.start_workflow(id, jobs, serializer.dump(context))
    end

    # def enqueue_initial_jobs
    #   backend.enqueue_pending
    # end

    def self.graph
      @graph ||= Graph.new
    end

    # private

    attr_reader :jobs

    def backend
      Pallets::Backends::Redis.new
    end

    def serializer
      Pallets::Serializers::Json.new
    end
  end
end
