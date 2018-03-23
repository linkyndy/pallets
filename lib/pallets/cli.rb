module Pallets
  class CLI
    def initialize
      @manager = Manager.new
      @signal_reader, @signal_writer = IO.pipe

      setup_signal_handlers
    end

    def run
      Pallets.logger.info "Starting the awesomeness of Pallets <3"

      @manager.start

      loop do
        # This blocks until signals are received
        signal_reader = IO.select([@signal_reader])
        signal = signal_reader.first[0].gets.chomp
        handle_signal(signal)
      end
    rescue Interrupt
      Pallets.logger.info "Shutting down..."
      @manager.shutdown
      Pallets.logger.info "Buh-bye!"
      exit
    end

    private

    def handle_signal(signal)
      case signal
      when 'INT'
        raise Interrupt
      end
    end

    def setup_signal_handlers
      %w(INT).each do |signal|
        trap signal do
          @signal_writer.puts signal
        end
      end
    end
  end
end
