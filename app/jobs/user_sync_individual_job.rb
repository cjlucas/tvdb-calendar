class UserSyncIndividualJob < ApplicationJob
  queue_as :default

  def perform(user_id)
    Rails.logger.info "UserSyncIndividualJob: Starting sync for user #{user_id}"
    user = User.find(user_id)
    UserSyncService.new(user).call
    Rails.logger.info "UserSyncIndividualJob: Completed sync for user #{user_id}"
  rescue => e
    Rails.logger.error "UserSyncIndividualJob: Failed to sync user #{user_id}: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    
    # Broadcast error to user
    ActionCable.server.broadcast(
      "sync_#{user_id}",
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