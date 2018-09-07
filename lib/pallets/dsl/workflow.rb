require 'active_support'

module Pallets
  module DSL
    module Workflow
      def task(*args, &block)
        options = args.extract_options!
        name, depends_on = if args.any?
          [args.first, options[:depends_on]]
        else
          options.first
        end
        raise ArgumentError, "A task must have a name" unless name
        # Handle nils, symbols or arrays consistently
        dependencies = Array(depends_on).compact
        graph.add(name, dependencies)

        max_failures = options[:max_failures] || Pallets.configuration.max_failures

        task_config[name.to_s] = {
          'max_failures' => max_failures
        }

        nil
      end
    end
  end
end
