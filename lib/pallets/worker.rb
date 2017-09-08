module Pallets
  class Worker
    attr_reader :manager

    def initialize(manager)
      @manager = manager
      @backend = manager.backend_class.new
    end

    def start
      @thread ||= Thread.new { work }
    end

    private

    attr_reader :thread, :backend

    def work
      loop do
        task, context = backend.pick_work
        klass = task['class_name'].constantize
        klass.new(context).run
        backend.save_work(task, context)
      end
    rescue Exception => ex

    end
  end
end
