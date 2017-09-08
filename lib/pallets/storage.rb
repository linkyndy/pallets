module Pallets
  module Storage
    module_function

    def push(item)
      queue << item
    end

    def pop
      queue.pop
    end

    def queue
      @queue ||= Queue.new
    end
  end
end
