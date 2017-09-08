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

    def build
      groups = tsort_each.with_index.slice_when do |(a, _), (b, _)|
        parents(a) != parents(b)
      end.map do |group|
        ttl = group.first[1]
        items = group.map { |item| [ttl, item[0]] }
      end.flatten(1)
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
