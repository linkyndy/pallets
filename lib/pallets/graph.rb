require 'tsort'

module Pallets
  class Graph
    include TSort

    def initialize
      @nodes = {}
    end

    def add(node, dependencies)
      @nodes[node] = dependencies
    end

    def parents(node)
      @nodes[node]
    end

    def empty?
      @nodes.empty?
    end

    # Returns nodes topologically sorted, together with their order (number of
    # nodes that have to be executed prior)
    def sorted_with_order
      # Identify groups of nodes that can be executed concurrently
      groups = tsort_each.slice_when { |a, b| parents(a) != parents(b) }

      # Assign order to each node
      i = 0
      groups.flat_map do |group|
        group_with_order = group.product([i])
        i += group.size
        group_with_order
      end
    end

    private

    def tsort_each_node(&block)
      @nodes.each_key(&block)
    end

    def tsort_each_child(node, &block)
      @nodes.fetch(node).each(&block)
    end
  end
end
