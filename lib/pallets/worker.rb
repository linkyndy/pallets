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

    def debug
      @thread.backtrace
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
      Pallets.logger.error "#{ex.class.name}: #{ex.message}", wid: id
      Pallets.logger.error ex.backtrace.join("\n"), wid: id unless ex.backtrace.nil?
      @manager.replace_worker(self)
    end

    def process(job)
      begin
        job_hash = serializer.load(job)
      rescue
        # We ensure only valid jobs are created. If something fishy reaches this
        # point, just give up on it
        backend.give_up(job, job)
        Pallets.logger.error "Could not deserialize #{job}. Gave up job", wid: id
        return
      end

      context = Context[
        serializer.load_context(backend.get_context(job_hash['wfid']))
      ]

      task_class = Pallets::Util.constantize(job_hash["task_class"])
      task = task_class.new(context)
      begin
        middleware.invoke(self, job_hash, context) do
          task.run
        end
      rescue => ex
        handle_job_error(ex, job, job_hash)
      else
        handle_job_success(context, job, job_hash)
      end
    end

    def handle_job_error(ex, job, job_hash)
      failures = job_hash.fetch('failures', 0) + 1
      new_job = serializer.dump(job_hash.merge(
        'failures' => failures,
        'given_up_at' => Time.now.to_f,
        'error_class' => ex.class.name,
        'error_message' => ex.message,
        'reason' => 'error'
      ))
      if failures < job_hash['max_failures']
        retry_at = Time.now.to_f + backoff_in_seconds(failures)
        backend.retry(new_job, job, retry_at)
      else
        backend.give_up(new_job, job)
      end
    end

    def handle_job_success(context, job, job_hash)
      backend.save(job_hash['wfid'], job, serializer.dump_context(context.buffer))
    end

    def backoff_in_seconds(count)
      count ** 4 + rand(6..10)
    end

    def backend
      @backend ||= Pallets.backend
    end

    def serializer
      @serializer ||= Pallets.serializer
    end

    def middleware
      @middleware ||= Pallets.middleware
    end
  end
end
