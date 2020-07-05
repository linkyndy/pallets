require 'logger'
require 'time'

module Pallets
  class Logger < ::Logger
    # Overwrite severity methods to add metadata capabilities
    %i[debug info warn error fatal unknown].each do |severity|
      define_method severity do |message|
        metadata = Thread.current[:pallets_log_metadata]
        return super(message) if metadata.nil?

        formatted_metadata = ' ' + metadata.map { |k, v| "#{k}=#{v}" }.join(' ')
        super(formatted_metadata) { message }
      end
    end

    def with_metadata(hash)
      Thread.current[:pallets_log_metadata] = hash
      yield
    ensure
      Thread.current[:pallets_log_metadata] = nil
    end

    module Formatters
      class Pretty < ::Logger::Formatter
        def call(severity, time, metadata, message)
          "#{time.utc.iso8601(4)} pid=#{Process.pid}#{metadata} #{severity}: #{message}\n"
        end
      end
    end
  end
end
