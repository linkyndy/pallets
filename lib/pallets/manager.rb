module Pallets
  class Manager
    attr_reader :workers, :backend_class

    def initialize(workers: 1, backend_class:)
      @workers = workers.times.map { Worker.new(self) }
      @backend_class = backend_class
    end

    def run
      workers.each(&:start)
    end
  end
end
