module Pallets
  module Middleware
    # Array-like class that acts like a stack and additionally provides the
    # means to wrap an operation with callable objects
    class Stack < Array
      def invoke(*args, &block)
        reverse.inject(block) do |memo, middleware|
          lambda { middleware.call(*args, &memo) }
        end.call
      end
    end
  end
end
