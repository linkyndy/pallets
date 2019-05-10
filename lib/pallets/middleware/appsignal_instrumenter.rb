require 'appsignal'

module Pallets
  module Middleware
    class AppsignalInstrumenter
      extend Appsignal::Hooks::Helpers

      def self.call(worker, job, context)
        job_status = nil
        transaction = Appsignal::Transaction.create(
          SecureRandom.uuid,
          Appsignal::Transaction::BACKGROUND_JOB,
          Appsignal::Transaction::GenericRequest.new(queue_start: job['created_at'])
        )

        Appsignal.instrument('perform_job.pallets') do
          begin
            yield
          rescue Exception => ex
            job_status = :failed
            transaction.set_error(ex)
            raise
          ensure
            transaction.set_action_if_nil("#{job['task_class']}#run (#{job['workflow_class']})")
            transaction.params = filtered_context(context)
            formatted_metadata(job).each { |kv| transaction.set_metadata(*kv) }
            transaction.set_http_or_background_queue_start
            Appsignal::Transaction.complete_current!
            Appsignal.increment_counter('pallets_job_count', 1, status: job_status || :successful)
          end
        end
      end

      def self.filtered_context(context)
        Appsignal::Utils::HashSanitizer.sanitize(
          context,
          Appsignal.config[:filter_parameters]
        )
      end

      def self.formatted_metadata(job)
        job.map { |k, v| [k, truncate(string_or_inspect(v))] }
      end
    end
  end
end
