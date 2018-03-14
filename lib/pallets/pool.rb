module Pallets
  class Pool
    def initialize(size:)
      @queue = SizedQueue.new(size)
      size.times { @queue << yield }
      Pallets.logger.info "[pool] Initialized pool"
    end

    def execute
      raise unless block_given?

      begin
        item = @queue.pop
        Pallets.logger.info "[pool] Item popped..."
        yield item
      ensure
        @queue << item
        Pallets.logger.info "[pool] ...Item pushed"
      end
    end
  end
end
