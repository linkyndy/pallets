require 'msgpack'

module Pallets
  module Serializers
    class Msgpack
      def dump(data)
        MessagePack.pack(data)
      end

      def load(data)
        # Strings coming from the backend are UTF-8 (Encoding.default_external)
        # while msgpack dumps ASCII-8BIT
        MessagePack.unpack(data.force_encoding('ASCII-8BIT'))
      end
    end
  end
end
