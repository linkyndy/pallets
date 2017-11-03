module Pallets
  class Manager
    attr_reader :workers, :backend_class, :serializer_class

    def initialize(workers: 1, backend_class: nil, serializer_class: nil)
      @backend_class = backend_class || Pallets::Backends::Redis
      @serializer_class = serializer_class || Pallets::Serializers::Json
      @workers = workers.times.map { Worker.new(self) }
    end

    def run
      workers.each(&:start)
    end

    def stop
      workers.each(&:stop)
    end
  end
end
