module Pallets
  module Middleware
    class JobLogger
      def self.call(worker, job, context)
        Pallets.logger.info 'Started', extract_metadata(worker.id, job)
        result = yield
        Pallets.logger.info 'Done', extract_metadata(worker.id, job)
        result
      rescue => ex
        Pallets.logger.warn "#{ex.class.name}: #{ex.message}", extract_metadata(worker.id, job)
        Pallets.logger.warn ex.backtrace.join("\n"), extract_metadata(worker.id, job) unless ex.backtrace.nil?
        raise
      end

      def self.extract_metadata(wid, job)
        {
          wid:  wid,
          wfid: job['wfid'],
          jid:  job['jid'],
          wf:   job['workflow_class'],
          tsk:  job['task_class'],
        }
      end
    end
  end
end
