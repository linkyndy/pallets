module Pallets
  module Backends
    class Base
      def pick_work
      end

      def save_work(wfid, job)
      end

      def discard(job)
      end

      def retry_work(job, old_job, retry_at)
      end

      def kill_work(job, old_job, killed_at)
      end

      def reschedule_jobs(earlier_than)
      end

      def start_workflow(wfid, jobs)
      end
    end
  end
end
