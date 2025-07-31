class UserSyncIndividualJob < ApplicationJob
  queue_as :default

  def perform(user_pin, force: false, otel_trace_context: nil)
    TRACER.in_span('user_sync_individual_job', attributes: {
      'job.class' => self.class.name,
      'job.id' => job_id,
      'user.pin' => user_pin,
      'sync.forced' => force
    }) do |span|
      user = User.find_by!(pin: user_pin)
      span.set_attribute('user.id', user.id)
      
      UserSyncService.new(user, force: force).call
      span.set_attribute('sync.result', 'success')
    end
  rescue InvalidPinError => e
    TRACER.in_span('user_sync_individual_job.invalid_pin_error', attributes: {
      'user.pin' => user_pin,
      'error.type' => 'InvalidPinError'
    }) do |span|
      span.record_exception(e)
      
      # Broadcast specific error to user
      ActionCable.server.broadcast(
        "sync_#{user_pin}",
        {
          current: 0,
          total: 0,
          percentage: 0,
          message: "PIN Invalid",
          error: true
        }
      )
    end
  rescue => e
    TRACER.in_span('user_sync_individual_job.sync_error', attributes: {
      'user.pin' => user_pin,
      'user.id' => user&.id
    }) do |span|
      span.record_exception(e)
      
      # Broadcast error to user
      ActionCable.server.broadcast(
        "sync_#{user_pin}",
        {
          current: 0,
          total: 0,
          percentage: 0,
          message: "Sync failed: #{e.message}",
          error: true
        }
      )
    end
  end
end
