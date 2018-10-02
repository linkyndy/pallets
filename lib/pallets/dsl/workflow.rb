module Pallets
  module DSL
    module Workflow
      def task(*args, **options, &block)
        name, depends_on = if args.any?
          [args.first, options[:depends_on]]
        else
          options.first
        end
        raise ArgumentError, "A task must have a name" unless name

        # Handle nils, symbols or arrays consistently
        name = name.to_sym
        dependencies = Array(depends_on).compact.map(&:to_sym)
        graph.add(name, dependencies)

        class_name = options[:class_name] || Pallets::Util.camelize(name)
        max_failures = options[:max_failures] || Pallets.configuration.max_failures

        task_config[name] = {
          'class_name' => class_name,
          'max_failures' => max_failures
        }

        nil
      end
    end
  end
end
