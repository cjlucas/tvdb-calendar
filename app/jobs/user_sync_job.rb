class UserSyncJob < ApplicationJob
  queue_as :default

  def perform(force: false)
    if force
      users_to_sync = User.all
      Rails.logger.info "UserSyncJob: Force sync - syncing all #{users_to_sync.count} users"
    else
      users_to_sync = User.where("last_synced_at IS NULL OR last_synced_at < ?", 1.hour.ago)
      Rails.logger.info "UserSyncJob: Found #{users_to_sync.count} users to sync"
    end

    users_to_sync.find_each do |user|
      begin
        UserSyncService.new(user, force: force).call
        Rails.logger.info "UserSyncJob: Successfully synced user ID #{user.id}"
      rescue => e
        Rails.logger.error "UserSyncJob: Failed to sync user ID #{user.id}: #{e.message}"
      end
    end
  end
end
