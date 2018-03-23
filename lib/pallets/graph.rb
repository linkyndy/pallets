require 'tsort'

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

    # Assigns indices to list of nodes, groups them together by parent, then
    # uses the first index for each group. Results in a list of node groups that
    # have the number of dependencies associated before when they can be safely
    # executed
    def sort_by_dependency_count
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
