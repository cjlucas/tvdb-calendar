module StructuredJobLogging
  extend ActiveSupport::Concern

  included do
    around_perform :with_structured_logging
  end

  private

  def with_structured_logging
    # Generate unique job ID
    job_id = SecureRandom.uuid

    # Add job_id to logging context
    Rails.logger.tagged(job_id: job_id) do
      start_time = Time.current

      # Log job start
      Rails.logger.info event: "job_started",
        job_id: job_id,
        job_class: self.class.name,
        queue: queue_name,
        arguments: arguments.to_s.truncate(500),
        scheduled_at: scheduled_at,
        enqueued_at: enqueued_at

      begin
        yield

        duration_ms = ((Time.current - start_time) * 1000).round(2)

        # Log job completion
        Rails.logger.info event: "job_completed",
          job_id: job_id,
          job_class: self.class.name,
          duration_ms: duration_ms

      rescue => e
        duration_ms = ((Time.current - start_time) * 1000).round(2)

        # Log job error
        Rails.logger.error event: "job_failed",
          job_id: job_id,
          job_class: self.class.name,
          duration_ms: duration_ms,
          error: e.message,
          error_class: e.class.name

        raise e
      end
    end
  end
end
