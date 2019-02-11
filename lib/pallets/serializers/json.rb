require 'json'

module Pallets
  module Serializers
    class Json < Base
      def dump(data)
        # TODO: Remove option after dropping support for Ruby 2.3
        JSON.generate(data, quirks_mode: true)
      end

      def load(data)
        JSON.parse(data, quirks_mode: true)
      end
    end
  end
end
