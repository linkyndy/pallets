module Pallets
  class Graph
    include TSort

    def initialize
      @nodes = {}
    end

    def add(task_name, dependencies)
      @nodes[task_name] = dependencies
    end

    def parents(node)
      nodes[node]
    end

    def children(node)
      nodes.select { |_, dependencies| dependencies.include? node }.keys
    end

    # private

    attr_reader :nodes

    def tsort_each_node(&block)
      nodes.each_key(&block)
    end

    def tsort_each_child(node, &block)
      nodes[node].each(&block)
    end
  end
end
