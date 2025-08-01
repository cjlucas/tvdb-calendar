class UserSyncIndividualJob < ApplicationJob
  queue_as :default

  def perform(user_pin, force: false)
    user = User.find_by!(pin: user_pin)
    Rails.logger.info "UserSyncIndividualJob: Starting sync for user ID #{user.id}#{force ? ' (forced)' : ''}"
    UserSyncService.new(user, force: force).call
    Rails.logger.info "UserSyncIndividualJob: Completed sync for user ID #{user.id}"
  rescue InvalidPinError => e
    Rails.logger.error "UserSyncIndividualJob: Invalid PIN for user ID #{user&.id || 'unknown'}: #{e.message}"

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
    Rails.logger.error "UserSyncIndividualJob: Failed to sync user ID #{user&.id || 'unknown'}: #{e.message}"
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
