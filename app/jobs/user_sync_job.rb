class UserSyncJob < ApplicationJob
  queue_as :default

  def perform(force: false, otel_trace_context: nil)
    TRACER.in_span('user_sync_job', attributes: {
      'job.class' => self.class.name,
      'job.id' => job_id,
      'sync.forced' => force
    }) do |span|
      if force
        users_to_sync = User.all
        span.set_attribute('sync.mode', 'force')
      else
        users_to_sync = User.where("last_synced_at IS NULL OR last_synced_at < ?", 1.hour.ago)
        span.set_attribute('sync.mode', 'scheduled')
      end

      span.set_attribute('users.count', users_to_sync.count)

      success_count = 0
      error_count = 0

      users_to_sync.find_each do |user|
        TRACER.in_span('user_sync_job.process_user', attributes: {
          'user.id' => user.id,
          'user.pin' => user.pin
        }) do |user_span|
          begin
            UserSyncService.new(user, force: force).call
            success_count += 1
            user_span.set_attribute('sync.result', 'success')
          rescue => e
            error_count += 1
            user_span.record_exception(e)
            user_span.set_attribute('sync.result', 'error')
          end
        end
      end

      span.set_attribute('sync.success_count', success_count)
      span.set_attribute('sync.error_count', error_count)
    end
  end
end
