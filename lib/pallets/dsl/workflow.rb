module Pallets
  module DSL
    module Workflow
      def task(arg=nil, as: nil, depends_on: nil, max_failures: nil, **kwargs)
        # Have to work more to keep Pallets' nice DSL valid in Ruby 2.7
        arg = !kwargs.empty? ? kwargs : arg
        raise ArgumentError, 'Task is incorrectly defined. It must receive '\
                             'either a name, or a name => dependencies pair as '\
                             'the first argument' unless arg

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
          'workflow_class' => self.name,
          'task_class' => task_class,
          'max_failures' => max_failures || Pallets.configuration.max_failures
        }

        nil
      end
    end
  end
end
