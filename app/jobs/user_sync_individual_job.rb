class UserSyncIndividualJob < ApplicationJob
  queue_as :default

  def perform(user_pin, force: false)
    user = User.find_by!(pin: user_pin)
    Rails.logger.info event: "individual_user_sync_started", user_id: user.id, forced: force
    UserSyncService.new(user, force: force).call
    Rails.logger.info event: "individual_user_sync_completed", user_id: user.id
  rescue InvalidPinError => e
    Rails.logger.error event: "invalid_pin_error", user_id: user&.id, user_pin: user_pin, error: e.message

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
  rescue => e
    Rails.logger.error event: "individual_sync_failed", user_id: user&.id, user_pin: user_pin, error: e.message
    Rails.logger.error e.backtrace.join("\n")

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
