module Pallets
  module DSL
    module Workflow
      def task(*args, **options, &block)
        name, depends_on = if args.any?
          [args.first, options[:depends_on]]
        else
          options.first
        end

        unless name
          raise WorkflowError, "Task has no name. Provide a name using " \
                               "`task :name, *args` or `task name: :arg` syntax"
        end

        # Handle nils, symbols or arrays consistently
        name = name.to_sym
        dependencies = Array(depends_on).compact.map(&:to_sym)
        graph.add(name, dependencies)

        class_name = options[:class_name] || Pallets::Util.camelize(name)
        max_failures = options[:max_failures]

        task_config[name] = {
          'class_name' => class_name
        }
        task_config[name]['max_failures'] = max_failures if max_failures

        nil
      end
    end
  end
end
