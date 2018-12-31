module Pallets
  # Hash-like class that additionally holds a buffer for all write operations
  class Context < Hash
    def []=(key, value)
      buffer[key] = value
      super
    end

    def buffer
      @buffer ||= {}
    end
  end
end
