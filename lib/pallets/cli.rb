require 'optparse'

module Pallets
  class CLI
    def initialize
      @manager = Manager.new
      @signal_reader, @signal_writer = IO.pipe

      parse_options
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

    def parse_options
      # TODO: -v for verbose, -d for debug, -q for quiet, -V for version
      OptionParser.new do |opts|
        opts.banner = 'Usage: pallets [options]'

        opts.on('-b', '--backend BACKEND', 'Backend to use') do |backend|
          Pallets.configuration.backend = backend
        end

        opts.on('-n', '--namespace NAMESPACE', 'Namespace to use for backend') do |namespace|
          Pallets.configuration.namespace = namespace
        end

        opts.on('-p', '--pool NUM', Integer, 'Size of backend pool') do |pool|
          Pallets.configuration.pool_size = pool
        end

        opts.on('-s', '--serializer SERIALIZER', 'Serializer to use') do |serializer|
          Pallets.configuration.serializer = serializer
        end

        opts.on('-u', '--blocking-timeout NUM', Integer, 'Seconds to wait for new work') do |blocking_timeout|
          Pallets.configuration.blocking_timeout = blocking_timeout
        end

        opts.on_tail('-h', '--help', 'Show this message') do
          puts opts
          exit
        end
      end.parse!
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
