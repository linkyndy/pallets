module Pallets
  class Task
    attr_reader :context

    def initialize(context = {})
      @context = context
    end

    def run
    end
  end
end
