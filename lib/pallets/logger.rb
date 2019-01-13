require 'logger'
require 'time'

module Pallets
  class Logger < ::Logger
    # Overwrite severity methods to add metadata capabilities
    %i[debug info warn error fatal unknown].each do |severity|
      define_method severity do |message, metadata = {}|
        return super(message) if metadata.empty?

        formatted_metadata = ' ' + metadata.map { |k, v| "#{k}=#{v}" }.join(' ')
        super(formatted_metadata) { message }
      end
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
