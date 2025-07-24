require "test_helper"

class UserSyncJobTest < ActiveJob::TestCase
  def setup
    @user1 = users(:one)
    @user2 = users(:two)

    # Set up users with different sync states
    @user1.update!(last_synced_at: 2.hours.ago) # Needs sync
    @user2.update!(last_synced_at: 30.minutes.ago) # Recently synced
  end

  test "should sync only users that need sync when force is false" do
    sync_service_calls = []

    # Mock UserSyncService to track which users are synced and with what force setting
    original_new = UserSyncService.method(:new)
    UserSyncService.define_singleton_method(:new) do |user, force: false|
      sync_service_calls << { user: user, force: force }

      # Return a mock service that responds to call
      mock_service = Object.new
      mock_service.define_singleton_method(:call) { true }
      mock_service
    end

    UserSyncJob.perform_now(force: false)

    # Should only sync user1 (who needs sync), not user2 (recently synced)
    synced_users = sync_service_calls.map { |call| call[:user] }
    assert_includes synced_users, @user1
    assert_not_includes synced_users, @user2

    # All calls should have force: false
    sync_service_calls.each do |call|
      assert_equal false, call[:force]
    end
  ensure
    UserSyncService.define_singleton_method(:new, original_new)
  end

  test "should sync all users when force is true" do
    sync_service_calls = []

    # Mock UserSyncService to track all sync calls
    original_new = UserSyncService.method(:new)
    UserSyncService.define_singleton_method(:new) do |user, force: false|
      sync_service_calls << { user: user, force: force }

      mock_service = Object.new
      mock_service.define_singleton_method(:call) { true }
      mock_service
    end

    UserSyncJob.perform_now(force: true)

    # Should sync both users when force is true
    synced_users = sync_service_calls.map { |call| call[:user] }
    assert_includes synced_users, @user1
    assert_includes synced_users, @user2

    # All calls should have force: true
    sync_service_calls.each do |call|
      assert_equal true, call[:force]
    end

    # Should sync all users in the system
    assert_equal User.count, sync_service_calls.length
  ensure
    UserSyncService.define_singleton_method(:new, original_new)
  end

  test "should default force parameter to false" do
    sync_service_calls = []

    original_new = UserSyncService.method(:new)
    UserSyncService.define_singleton_method(:new) do |user, force: false|
      sync_service_calls << { user: user, force: force }

      mock_service = Object.new
      mock_service.define_singleton_method(:call) { true }
      mock_service
    end

    # Call without force parameter
    UserSyncJob.perform_now

    # Should only sync users that need sync (default behavior)
    synced_users = sync_service_calls.map { |call| call[:user] }
    assert_includes synced_users, @user1
    assert_not_includes synced_users, @user2

    # All force values should be false
    sync_service_calls.each do |call|
      assert_equal false, call[:force]
    end
  ensure
    UserSyncService.define_singleton_method(:new, original_new)
  end

  test "should handle sync errors gracefully" do
    sync_service_calls = []

    # Mock UserSyncService to raise error for one user
    original_new = UserSyncService.method(:new)
    UserSyncService.define_singleton_method(:new) do |user, force: false|
      sync_service_calls << { user: user, force: force }

      mock_service = Object.new
      if user == @user1
        mock_service.define_singleton_method(:call) { raise StandardError.new("Sync failed") }
      else
        mock_service.define_singleton_method(:call) { true }
      end
      mock_service
    end

    # Should not raise error, should continue processing other users
    assert_nothing_raised do
      UserSyncJob.perform_now(force: true)
    end

    # Should have attempted to sync all users despite the error
    assert_equal User.count, sync_service_calls.length
  ensure
    UserSyncService.define_singleton_method(:new, original_new)
  end

  test "should use different user selection logic based on force parameter" do
    # Test the actual user selection queries
    users_needing_sync = User.where("last_synced_at IS NULL OR last_synced_at < ?", 1.hour.ago)
    all_users = User.all

    # Verify our test setup is correct
    assert_includes users_needing_sync, @user1
    assert_not_includes users_needing_sync, @user2
    assert_includes all_users, @user1
    assert_includes all_users, @user2

    # The job should use different queries based on force parameter
    # This is tested implicitly by the previous tests, but we verify the queries work as expected
    assert users_needing_sync.count < all_users.count, "Should have fewer users needing sync than total users"
  end
end
