module Pallets
  class Manager
    attr_reader :workers, :timeout

    # TODO: Extract arguments to config
    def initialize(workers: 2, timeout: 7)
      @workers = workers.times.map { Worker.new(self) }
      @scheduler = Scheduler.new(self)
      @timeout = timeout
      @lock = Mutex.new
      @needs_to_stop = false
    end

    def start
      @workers.each(&:start)
      @scheduler.start
    end

    # Attempt to gracefully shutdown every worker. If any is still busy after
    # the given timeout, hard shutdown it. We don't need to worry about lost
    # jobs caused by the hard shutdown; there is a reliability list that
    # contains all active jobs, which will be automatically requeued upon next
    # start
    def shutdown
      @needs_to_stop = true

      @workers.each(&:graceful_shutdown)
      @scheduler.shutdown

      Pallets.logger.info 'Waiting for workers to finish their jobs...'
      @timeout.times do
        sleep 1
        return if @workers.empty?
      end

      @workers.each(&:hard_shutdown)
      # Ensure Pallets::Shutdown got propagated and workers finished; if not,
      # their threads will be killed anyway when the manager quits
      sleep 0.5
    end

    def remove_worker(worker)
      Pallets.logger.info "removing worker"
      @lock.synchronize { @workers.delete(worker) }
    end

    def restart_worker(worker)
      Pallets.logger.info "restarting worker"
      @lock.synchronize do
        @workers.delete(worker)

        return if @needs_to_stop

        worker = Worker.new(self)
        @workers << worker
        worker.start
      end
    end
  end
end
