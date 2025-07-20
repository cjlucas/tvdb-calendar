class UserSyncJob < ApplicationJob
  queue_as :default

  def perform
    users_to_sync = User.where('last_synced_at IS NULL OR last_synced_at < ?', 1.hour.ago)
    
    Rails.logger.info "UserSyncJob: Found #{users_to_sync.count} users to sync"
    
    users_to_sync.find_each do |user|
      begin
        UserSyncService.new(user).call
        Rails.logger.info "UserSyncJob: Successfully synced user ID #{user.id}"
      rescue => e
        Rails.logger.error "UserSyncJob: Failed to sync user ID #{user.id}: #{e.message}"
      end
    end
  end
end