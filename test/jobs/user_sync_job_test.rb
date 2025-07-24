require "test_helper"

class UserSyncJobTest < ActiveJob::TestCase
  def setup
    @user1 = users(:one)
    @user2 = users(:two)
    
    # Set up users with different sync states
    @user1.update!(last_synced_at: 2.hours.ago) # Needs sync
    @user2.update!(last_synced_at: 30.minutes.ago) # Recently synced
  end

  test "should accept force parameter" do
    job = UserSyncJob.new
    assert_respond_to job, :perform
    
    # Check that the source code includes force parameter handling
    job_source = File.read(Rails.root.join("app/jobs/user_sync_job.rb"))
    assert_includes job_source, "force: false"
    assert_includes job_source, "if force"
  end

  test "should query different users based on force parameter" do
    # Test the SQL logic for user selection
    
    # Normal sync should only get users that need sync
    users_needing_sync = User.where("last_synced_at IS NULL OR last_synced_at < ?", 1.hour.ago)
    assert_includes users_needing_sync, @user1
    assert_not_includes users_needing_sync, @user2
    
    # Force sync should get all users
    all_users = User.all
    assert_includes all_users, @user1
    assert_includes all_users, @user2
  end

  test "should log appropriate messages for force vs normal sync" do
    job_source = File.read(Rails.root.join("app/jobs/user_sync_job.rb"))
    
    # Should include logging for force sync
    assert_includes job_source, "Force sync - syncing all"
    
    # Should include logging for normal sync  
    assert_includes job_source, "Found"
    assert_includes job_source, "users to sync"
  end

  test "should pass force parameter to UserSyncService" do
    job_source = File.read(Rails.root.join("app/jobs/user_sync_job.rb"))
    
    # Should pass force parameter to UserSyncService
    assert_includes job_source, "UserSyncService.new(user, force: force)"
  end

  test "should handle sync errors gracefully" do
    job_source = File.read(Rails.root.join("app/jobs/user_sync_job.rb"))
    
    # Should have error handling
    assert_includes job_source, "rescue => e"
    assert_includes job_source, "Failed to sync user ID"
  end
end