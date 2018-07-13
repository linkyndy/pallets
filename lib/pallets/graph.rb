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

    # Assigns indices to list of nodes, groups them together by parent, then
    # uses the first index for each group. Results in a list of node groups that
    # have the number of dependencies associated before when they can be safely
    # executed
    def sort_by_dependency_count
      groups = tsort_each.with_index.slice_when do |(a, _), (b, _)|
        parents(a) != parents(b)
      end.flat_map do |group|
        count = group.first[1]
        group.map { |item| [count, item[0]] }
      end
    end

    private

    def tsort_each_node(&block)
      @nodes.each_key(&block)
    end

    def tsort_each_child(node, &block)
      @nodes[node].each(&block)
    end
  end
end
