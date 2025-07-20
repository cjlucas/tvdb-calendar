class UserSyncIndividualJob < ApplicationJob
  queue_as :default

  def perform(user_pin)
    Rails.logger.info "UserSyncIndividualJob: Starting sync for user with PIN #{user_pin}"
    user = User.find_by!(pin: user_pin)
    UserSyncService.new(user).call
    Rails.logger.info "UserSyncIndividualJob: Completed sync for user with PIN #{user_pin}"
  rescue => e
    Rails.logger.error "UserSyncIndividualJob: Failed to sync user with PIN #{user_pin}: #{e.message}"
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