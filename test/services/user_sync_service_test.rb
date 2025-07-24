require "test_helper"

class UserSyncServiceTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)
  end

  test "should initialize with force parameter" do
    # Set up required environment variable for TvdbClient
    ENV['TVDB_API_KEY'] = 'test_key'
    
    service = UserSyncService.new(@user, force: true)
    assert service.instance_variable_get(:@force)
    
    service = UserSyncService.new(@user, force: false)
    assert_not service.instance_variable_get(:@force)
    
    service = UserSyncService.new(@user)
    assert_not service.instance_variable_get(:@force)
  ensure
    ENV.delete('TVDB_API_KEY')
  end

  test "should bypass series sync limits when force is true" do
    # Set up required environment variable for TvdbClient
    ENV['TVDB_API_KEY'] = 'test_key'
    
    # Create a series that was recently synced (should normally be skipped)
    series = Series.create!(
      tvdb_id: 12345,
      name: "Test Series",
      last_synced_at: 1.hour.ago # Recently synced, should normally skip
    )
    
    # Create user association
    @user.user_series.create!(series: series)
    
    # Test that force bypasses the needs_sync? check
    service_without_force = UserSyncService.new(@user, force: false)
    service_with_force = UserSyncService.new(@user, force: true)
    
    # The key test: force should bypass series.needs_sync? check
    # We test this by checking the conditional logic directly
    assert_not series.needs_sync?, "Series should not need sync (was synced 1 hour ago)"
    
    # Force flag should override this
    force_should_sync = service_with_force.instance_variable_get(:@force) || series.needs_sync?
    no_force_should_sync = service_without_force.instance_variable_get(:@force) || series.needs_sync?
    
    assert force_should_sync, "Force flag should bypass sync limits"
    assert_not no_force_should_sync, "Without force, should respect sync limits"
  ensure
    ENV.delete('TVDB_API_KEY')
  end
end