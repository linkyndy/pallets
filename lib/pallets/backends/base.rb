module Pallets
  module Backends
    class Base
      def pick
        raise NotImplementedError
      end

      def save(wfid, job)
        raise NotImplementedError
      end

      def discard(job)
        raise NotImplementedError
      end

      def retry(job, old_job, at)
        raise NotImplementedError
      end

      def kill(job, old_job, at)
        raise NotImplementedError
      end

      def reschedule(earlier_than)
        raise NotImplementedError
      end

      def start_workflow(wfid, jobs_with_dependencies)
        raise NotImplementedError
      end
    end
  end
end
