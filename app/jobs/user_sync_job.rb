class UserSyncJob < ApplicationJob
  queue_as :default

  def perform(force: false)
    if force
      users_to_sync = User.all
      Rails.logger.info event: "user_sync_job_started", mode: "force", user_count: users_to_sync.count
    else
      users_to_sync = User.where("last_synced_at IS NULL OR last_synced_at < ?", 1.hour.ago)
      Rails.logger.info event: "user_sync_job_started", mode: "scheduled", user_count: users_to_sync.count
    end

    users_to_sync.find_each do |user|
      begin
        UserSyncService.new(user, force: force).call
        Rails.logger.info event: "user_sync_success", user_id: user.id
      rescue => e
        Rails.logger.error event: "user_sync_error", user_id: user.id, error: e.message
      end
    end
  end
end
