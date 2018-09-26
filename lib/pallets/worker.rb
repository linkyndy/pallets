module Pallets
  class Worker
    attr_reader :manager

    def initialize(manager)
      @manager = manager
      @current_job = nil
      @needs_to_stop = false
      @thread = nil
    end

    def start
      @thread ||= Thread.new { work }
    end

    def graceful_shutdown
      @needs_to_stop = true
    end

    def hard_shutdown
      return unless @thread
      @thread.raise Pallets::Shutdown
    end

    def needs_to_stop?
      @needs_to_stop
    end

    def id
      "W#{@thread.object_id.to_s(36)}".upcase if @thread
    end

    private

    def work
      loop do
        break if needs_to_stop?

        @current_job = backend.pick
        # No need to requeue because of the reliability queue
        break if needs_to_stop?
        next if @current_job.nil?

        process @current_job

        @current_job = nil
      end
      @manager.remove_worker(self)
    rescue Pallets::Shutdown
      @manager.remove_worker(self)
    rescue => ex
      @manager.replace_worker(self)
    end

    def process(job)
      Pallets.logger.info "[#{id}] Picked job: #{job}"
      begin
        job_hash = serializer.load(job)
      rescue
        # We ensure only valid jobs are created. If something fishy reaches this
        # point, just discard it
        backend.discard(job)
        return
      end

      task_class = job_hash["class_name"].constantize
      task = task_class.new(job_hash["context"])
      begin
        task.run
      rescue => ex
        handle_job_error(ex, job, job_hash)
      else
        backend.save(job_hash["workflow_id"], job)
        Pallets.logger.info "[#{id}] Successfully processed #{job}"
      end
    end

    def handle_job_error(ex, job, job_hash)
      Pallets.logger.error "[#{id}] Error while processing: #{ex}"
      failures = job_hash.fetch('failures', 0) + 1
      new_job = serializer.dump(job_hash.merge(
        'failures' => failures,
        'failed_at' => Time.now.to_f,
        'error_class' => ex.class.name,
        'error_message' => ex.message
      ))
      if failures < job_hash['max_failures']
        retry_at = Time.now.to_f + backoff_in_seconds(failures)
        backend.retry(new_job, job, retry_at)
        Pallets.logger.info "[#{id}] Scheduled job for retry"
      else
        backend.give_up(new_job, job, Time.now.to_f)
        Pallets.logger.info "[#{id}] Given up on job"
      end
    end

    def backoff_in_seconds(count)
      count ** 4 + 6
    end

    def backend
      @backend ||= Pallets.backend
    end

    def serializer
      @serializer ||= Pallets.serializer
    end
  end
end
