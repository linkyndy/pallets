module Pallets
  module Backends
    class Base
      # Picks a job that is ready for processing
      def pick
        raise NotImplementedError
      end

      def get_context(wfid)
        raise NotImplementedError
      end

      # Saves a job after successfully processing it
      def save(wfid, jid, job, context_buffer)
        raise NotImplementedError
      end

      # Schedules a failed job for retry
      def retry(job, old_job, at)
        raise NotImplementedError
      end

      # Discards malformed job
      def discard(job)
        raise NotImplementedError
      end

      # Gives up job after repeteadly failing to process it
      def give_up(wfid, job, old_job)
        raise NotImplementedError
      end

      def reschedule_all(earlier_than)
        raise NotImplementedError
      end

      def run_workflow(wfid, jobs, jobmasks, context)
        raise NotImplementedError
      end
    end
  end
end
