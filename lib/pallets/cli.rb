require 'optparse'

module Pallets
  class CLI
    def initialize
      parse_options
      setup_signal_handlers

      @manager = Manager.new
      @signal_queue = Queue.new
    end

    def run
      Pallets.logger.info 'Starting the awesome Pallets <3'
      Pallets.logger.info "Running on #{RUBY_DESCRIPTION}"

      @manager.start

      loop do
        # This blocks until signals are received
        handle_signal(@signal_queue.pop)
      end
    rescue Interrupt
      Pallets.logger.info 'Shutting down...'
      @manager.shutdown
      Pallets.logger.info 'Buh-bye!'
      exit
    end

    private

    def handle_signal(signal)
      case signal
      when 'INT', 'TERM'
        raise Interrupt
      when 'TTIN'
        print_backtraces
      end
    end

    def print_backtraces
      (@manager.workers + [@manager.scheduler]).each do |actor|
        Pallets.logger.info "Debugging #{actor.id}"
        Pallets.logger.info actor.debug.join("\n") unless actor.debug.nil?
      end
    end

    def parse_options
      OptionParser.new do |opts|
        opts.banner = 'Usage: pallets [options]'

        opts.on('-b', '--backend NAME', 'Backend to use') do |backend|
          Pallets.configuration.backend = backend
        end

        opts.on('-c', '--concurrency NUM', Integer, 'Number of workers to start') do |concurrency|
          Pallets.configuration.concurrency = concurrency
        end

        opts.on('-f', '--max-failures NUM', Integer, 'Maximum allowed number of failures per task') do |max_failures|
          Pallets.configuration.max_failures = max_failures
        end

        opts.on('-l', '--failed-job-lifespan NUM', Integer, 'Seconds a job stays in the given up set') do |failed_job_lifespan|
          Pallets.configuration.failed_job_lifespan = failed_job_lifespan
        end

        opts.on('-p', '--pool-size NUM', Integer, 'Size of backend pool') do |pool_size|
          Pallets.configuration.pool_size = pool_size
        end

        opts.on('-q', '--quiet', 'Output less logs') do
          Pallets.logger.level = Logger::ERROR
        end

        opts.on('-r', '--require PATH', 'Path to file containing workflow definitions or directory containing Rails application') do |path|
          if File.directory?(path)
            require File.expand_path("#{path}/config/environment.rb")
          else
            require(path)
          end
        end

        opts.on('-s', '--serializer NAME', 'Serializer to use') do |serializer|
          Pallets.configuration.serializer = serializer
        end

        opts.on('-t', '--job-timeout NUM', Integer, 'Seconds allowed for a job to be processed') do |job_timeout|
          Pallets.configuration.job_timeout = job_timeout
        end

        opts.on('-u', '--blocking-timeout NUM', Integer, 'Seconds to block while waiting for work') do |blocking_timeout|
          Pallets.configuration.blocking_timeout = blocking_timeout
        end

        opts.on('-v', '--verbose', 'Output more logs') do
          Pallets.logger.level = Logger::DEBUG
        end

        opts.on('--version', 'Version of Pallets') do
          puts "Pallets v#{Pallets::VERSION}"
          exit
        end

        opts.on_tail('-h', '--help', 'Show this message') do
          puts opts
          exit
        end
      end.parse!
    end

    def setup_signal_handlers
      %w(INT TERM TTIN).each do |signal|
        trap signal do
          @signal_queue.push signal
        end
      end
    end
  end
end
