module Pallets
  module Backends
    class Base
      def pick
        raise NotImplementedError
      end

      def save(workflow_id, job)
        raise NotImplementedError
      end

      def discard(job)
        raise NotImplementedError
      end

      def retry(job, old_job, at)
        raise NotImplementedError
      end

      def give_up(job, old_job, at)
        raise NotImplementedError
      end

      def reschedule_all(earlier_than)
        raise NotImplementedError
      end

      def run_workflow(workflow_id, jobs_with_dependencies)
        raise NotImplementedError
      end
    end
  end
end
