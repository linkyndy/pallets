module Pallets
  module Backends
    class Base
      # Picks a job that is ready for processing
      def pick
        raise NotImplementedError
      end

      def get_context_log(workflow_id)
        raise NotImplementedError
      end

      # Saves a job after successfully processing it
      def save(workflow_id, job, context_log_item)
        raise NotImplementedError
      end

      # Discard a malformed job
      def discard(job)
        raise NotImplementedError
      end

      # Schedule a failed job for retry
      def retry(job, old_job, at)
        raise NotImplementedError
      end

      # Give up job after repeteadly failing to process it
      def give_up(job, old_job, at)
        raise NotImplementedError
      end

      def reschedule_all(earlier_than)
        raise NotImplementedError
      end

      def run_workflow(workflow_id, jobs_with_dependencies, initial_context_log, number_of_jobs)
        raise NotImplementedError
      end
    end
  end
end
