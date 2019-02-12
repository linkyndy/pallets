module Pallets
  module Serializers
    class Base
      def dump(data)
        raise NotImplementedError
      end

      def load(data)
        raise NotImplementedError
      end

      alias_method :dump_job, :dump
      alias_method :load_job, :load

      # Context hashes only need their values (de)serialized
      def dump_context(data)
        data.map { |k, v| [k.to_s, dump(v)] }.to_h
      end

      def load_context(data)
        data.map { |k, v| [k, load(v)] }.to_h
      end
    end
  end
end
