module Pallets
  class Scheduler
    def initialize(manager)
      @manager = manager
      @needs_to_stop = false
      @thread = nil
    end

    def start
      Pallets.logger.info "[scheduler] starting"
      @thread ||= Thread.new { work }
    end

    def shutdown
      Pallets.logger.info "[scheduler #{id}] shutdown..."
      @needs_to_stop = true

      Pallets.logger.info "[scheduler #{id}] waiting to shutdown..."
      return unless @thread
      @thread.join
    end

    def needs_to_stop?
      @needs_to_stop
    end

    def id
      "S#{@thread.object_id.to_s(36)}".upcase if @thread
    end

    private

    def work
      loop do
        break if needs_to_stop?

        Pallets.logger.info "[scheduler #{id}] scheduling"
        backend.reschedule(Time.now.to_f)
        Pallets.logger.info "[scheduler #{id}] done scheduling"

        wait_a_bit
      end
      Pallets.logger.info "[scheduler #{id}] done"
    end

    def wait_a_bit
      # Wait for roughly 10 seconds
      # We don't want to block the entire polling interval, since we want to
      # deal with shutdowns synchronously and as fast as possible
      10.times do
        break if needs_to_stop?
        sleep 1
      end
    end

    def backend
      @backend ||= Pallets.backend
    end
  end
end
