module Pallets
  # Hash-like class that additionally holds a buffer for all write operations
  # that occur after initialization
  class Context < Hash
    def []=(key, value)
      buffer[key] = value
      super
    end

    def merge!(other_hash)
      buffer.merge!(other_hash)
      super
    end

    def buffer
      @buffer ||= {}
    end
  end
end
