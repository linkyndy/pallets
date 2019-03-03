module Pallets
  module DSL
    module Workflow
      def task(arg, depends_on: nil, max_failures: nil, &block)
        klass, dependencies = case arg
        when Hash
          # The `task Foo => Bar` notation
          arg.first
        else
          # The `task Foo, depends_on: Bar` notation
          [arg, depends_on]
        end

        class_name = klass.to_s
        dependencies = Array(dependencies).compact.uniq.map(&:to_s)
        graph.add(class_name, dependencies)

        task_config[class_name] = {
          'class_name' => class_name,
          'max_failures' => max_failures || Pallets.configuration.max_failures
        }

        nil
      end
    end
  end
end
