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

workflow = ProcessOrder.new(order_id: 123, method: :visa)
workflow.start
=> abc123
workflow.finished?
=> false
workflow = ProcessOrder.find('abc123')
workflow.tasks
=> { :buy => :finished, :pay => :running }

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

    attr_reader :id

    def initialize(context = {})
      @id = nil
      @jobs = {}
      @pending_jobs = []
      @context = context
    end

    def start
      @id = self.class.generate_id
      create_jobs
      save
      enqueue_initial_jobs
    end

    def create_jobs
      jobs = []
      graph.tsort.reverse_each.with_object({}) do |node, jids|
        next_jids = graph.children(node).map { |child| jids[child] }
        jobs << job = {
          'jid' => SecureRandom.hex,
          'class' => node.to_s.camelize,
          'wfid' => id,
          'next_jids' => next_jids,
          'dependency_count' => graph.parents(node).size
        }
        jids[node] = job['jid']
      end

      self.class.backend.create_jobs(jobs)

      graph.tsort.reverse_each do |node|
        next_jids = graph.children(node).map { |child_node| @jobs[child_node]['jid'] }
        @jobs[node] = {
          'jid' => SecureRandom.hex,
          'class' => node.to_s.camelize,
          'wfid' => id,
          'next_jids' => next_jids
        }
        @pending_jobs << [graph.parents(node).size, @jobs[node]['jid']]
      end
    end

    def save
      backend.save(jobs, pending_jobs, context)
    end

    def self.graph
      @graph ||= Graph.new
    end

    def self.generate_id
      initials = name.gsub(/[^A-Z]+([A-Z])/, '\1')[0,3]
      random = SecureRandom.hex(3)
      "W#{initials}#{random}".upcase
    end

    # private

    attr_reader :jobs

    def self.backend
      Pallets::Backends::Redis
    end
  end
end
