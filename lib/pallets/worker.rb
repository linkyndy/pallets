module Pallets
  class Worker
    attr_reader :manager

    def initialize(manager)
      @manager = manager
      @backend = manager.backend_class.new
      @serializer = manager.serializer_class.new
      @current_job = nil
      @needs_to_stop = false
    end

    def start
      Pallets.logger.info "[worker] starting"
      @thread ||= Thread.new { work }
    end

    def graceful_shutdown
      Pallets.logger.info "[worker #{@thread.object_id}] graceful shutdown..."
      @needs_to_stop = true
    end

    def hard_shutdown
      Pallets.logger.info "[worker #{@thread.object_id}] hard shutdown, killing"
      @thread.kill
      Pallets.logger.info "[worker #{@thread.object_id}] killed"
    end

    private

    def work
      loop do
        break if @needs_to_stop

        Pallets.logger.info "[worker #{id}] picking work"
        @current_job = @backend.pick_work id
        break if @needs_to_stop # no requeue because of extra reliable queue
        if @current_job.nil?
          Pallets.logger.info "[worker #{id}] nothing new, skipping"
          next
        end

        Pallets.logger.info "[worker #{id}] picked job: #{@current_job}"
        job_hash = @serializer.load(@current_job)
        Pallets.logger.info "[worker #{id}] working"
        task = job_hash["class_name"].constantize
        task.new(job_hash["context"]).run
        Pallets.logger.info "[worker #{id}] saving work"
        @backend.save_work(job_hash["wfid"], @current_job, id)
        @current_job = nil
      end
      Pallets.logger.info "[worker #{id}] done"
      @manager.remove_worker(self)
    rescue Exception => ex
      # put back work to queue, but with retries (don"t wanna continuously
      # rework on failing jobs)
      # backend.put_back_work(job)
      Pallets.logger.error "[worker #{id}] died:"
      Pallets.logger.error ex
      # Pallets.logger.error ex.backtrace
      @manager.restart_worker(self)
    end

    def id
      Thread.current.object_id
    end
  end
end
