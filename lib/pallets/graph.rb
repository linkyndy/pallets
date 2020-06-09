require 'tsort'

module Pallets
  class Graph
    include TSort

    def initialize
      @nodes = {}
    end

    def add(node, dependencies)
      raise WorkflowError, "Task #{node} is already defined in this workflow. "\
                           "Use `task '#{node}', as: 'FooBar'` to define an "\
                           "alias and reuse task" if nodes.key?(node)

      nodes[node] = dependencies
    end

    def parents(node)
      nodes[node]
    end

    def empty?
      nodes.empty?
    end

    def each
      return enum_for(__method__) unless block_given?

      tsort_each do |node|
        yield(node, parents(node))
      end
    end

    private

    attr_reader :nodes

    def tsort_each_node(&block)
      nodes.each_key(&block)
    end

    def tsort_each_child(node, &block)
      nodes.fetch(node).each(&block)
    rescue KeyError
      raise WorkflowError, "Task #{node} is marked as a dependency but not defined"
    end
  end
end
