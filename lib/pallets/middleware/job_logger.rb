module Pallets
  module Middleware
    class JobLogger
      def self.call(worker, job, context)
        Pallets.logger.with_metadata(extract_metadata(worker.id, job)) do
          Pallets.logger.info 'Started'
          result = yield
          Pallets.logger.info 'Done'
          result
        rescue => ex
          Pallets.logger.warn 'Failed'
          Pallets.logger.warn "#{ex.class.name}: #{ex.message}"
          Pallets.logger.warn ex.backtrace.join("\n") unless ex.backtrace.nil?
          raise
        end
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
