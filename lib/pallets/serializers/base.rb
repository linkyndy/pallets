module Pallets
  module Serializers
    class Base
      def dump(data)
        raise NotImplementedError
      end

      def load(data)
        raise NotImplementedError
      end
    end
  end
end
