require 'logger'

module Pallets
  class Worker
    attr_reader :manager, :logger

    def initialize(manager)
      @manager = manager
      @backend = manager.backend_class.new
      @serializer = manager.serializer_class.new
      @needs_to_stop = false
      @logger = Logger.new(STDOUT)
    end

    def start
      logger.info '[worker] starting'
      @thread ||= Thread.new { work }
    end

    def stop
      logger.info '[worker] stopping'
      @needs_to_stop = true
      @thread.raise StandardError
      @thread.join
    end

    private

    attr_reader :thread, :backend

    def work
      loop do
        break if @needs_to_stop

        logger.info '[worker] picking work'
        job, context = backend.pick_work
        job = serializer.load(job)
        context = serializer.load(context)
        logger.info '[worker] working'
        task = job['class_name'].constantize
        task.new(context).run
        logger.info '[worker] saving work'
        backend.save_work(job, serializer.dump(context))
      end
      logger.info '[worker] stopped'
    rescue Exception => ex
      # put back work to queue
      # backend.put_back_work(job)
      print '[worker] died'
      # print ex
    end
  end
end
