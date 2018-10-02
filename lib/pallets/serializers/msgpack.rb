require 'msgpack'

module Pallets
  module Serializers
    class Msgpack
      def dump(data)
        MessagePack.pack(data)
      end

      def load(data)
        MessagePack.unpack(data)
      end
    end
  end
end
