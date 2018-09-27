module Pallets
  class Pool
    def initialize(size)
      raise ArgumentError, 'Pool needs a block to initialize' unless block_given?

      @queue = Queue.new
      @size = size
      size.times { @queue << yield }
    end

    def size
      @queue.size
    end

    def execute
      raise ArgumentError, 'Pool needs a block to execute' unless block_given?

      begin
        item = @queue.pop
        yield item
      ensure
        @queue << item
      end
    end
  end
end
