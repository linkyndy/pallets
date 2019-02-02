module Pallets
  class Manager
    attr_reader :workers, :scheduler

    def initialize(concurrency: Pallets.configuration.concurrency)
      @workers = concurrency.times.map { Worker.new(self) }
      @scheduler = Scheduler.new(self)
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

      @workers.reverse_each(&:graceful_shutdown)
      @scheduler.shutdown

      Pallets.logger.info 'Waiting for workers to finish their jobs...'
      # Wait for 10 seconds at most
      10.times do
        return if @workers.empty?
        sleep 1
      end

      @workers.reverse_each(&:hard_shutdown)
      # Ensure Pallets::Shutdown got propagated and workers finished; if not,
      # their threads will be killed anyway when the manager quits
      sleep 0.5
    end

    def remove_worker(worker)
      @lock.synchronize { @workers.delete(worker) }
    end

    def replace_worker(worker)
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
