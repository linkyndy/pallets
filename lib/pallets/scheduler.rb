module Pallets
  class Scheduler
    def initialize(manager)
      @manager = manager
      @needs_to_stop = false
      @thread = nil
    end

    def start
      @thread ||= Thread.new { work }
    end

    def shutdown
      @needs_to_stop = true

      return unless @thread
      @thread.join
    end

    def needs_to_stop?
      @needs_to_stop
    end

    def debug
      @thread.backtrace
    end

    def id
      "S#{@thread.object_id.to_s(36)}".upcase if @thread
    end

    private

    def work
      loop do
        break if needs_to_stop?

        backend.reschedule_all(Time.now.to_f)
        wait_a_bit
      end
    end

    def wait_a_bit(seconds = Pallets.configuration.scheduler_polling_interval)
      # Wait for roughly the configured number of seconds
      # We don't want to block the entire polling interval, since we want to
      # deal with shutdowns synchronously and as fast as possible
      seconds.times do
        break if needs_to_stop?
        sleep 1
      end
    end

    def backend
      @backend ||= Pallets.backend
    end
  end
end
