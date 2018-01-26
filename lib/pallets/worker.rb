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
      # @thread.raise StandardError
      if !@thread.join(5).nil?
        logger.info '[worker] stopped'
      else
        # TODO: put job back in the queue so we don't lose it before killing the thread
        logger.info '[worker] not stopped, killing'
        # either busy with a long running job (more than join limit), either
        # waiting with brpop on the queue
        @thread.kill
        logger.info '[worker] killed'
      end
    end

    private

    attr_reader :thread, :backend, :serializer

    def work
      loop do
        break if @needs_to_stop

        logger.info '[worker] picking work'
        # job, context = backend.pick_work
        job = backend.pick_work
        logger.info "[worker] picked job: #{job}"
        job = serializer.load(job)
        logger.info '[worker] working'
        task = job['class_name'].constantize
        task.new(job['context']).run
        logger.info '[worker] saving work'
        # backend.save_work(job['wfid'], serializer.dump(context))
        backend.save_work(job['wfid'])
      end
      logger.info '[worker] stopped'
    rescue Exception => ex
      # put back work to queue, but with retries (don't wanna continuously
      # rework on failing jobs)
      # backend.put_back_work(job)
      logger.error '[worker] died:'
      logger.error ex
      logger.error ex.backtrace
    end
  end
end
