module Pallets
  module DSL
    module Workflow
      def task(arg, as: nil, depends_on: nil, max_failures: nil, &block)
        klass, dependencies = case arg
        when Hash
          # The `task Foo => Bar` notation
          arg.first
        else
          # The `task Foo, depends_on: Bar` notation
          [arg, depends_on]
        end

        task_class = klass.to_s
        as ||= task_class

        dependencies = Array(dependencies).compact.uniq.map(&:to_s)
        graph.add(as, dependencies)

        task_config[as] = {
          'task_class' => task_class,
          'max_failures' => max_failures || Pallets.configuration.max_failures
        }

        nil
      end
    end
  end
end
