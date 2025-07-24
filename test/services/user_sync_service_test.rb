require "test_helper"

class UserSyncServiceTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)
    # Set up required environment variable for TvdbClient
    ENV["TVDB_API_KEY"] = "test_key"
  end

  def teardown
    ENV.delete("TVDB_API_KEY")
  end

  test "should initialize with force parameter" do
    service = UserSyncService.new(@user, force: true)
    assert service.instance_variable_get(:@force)

    service = UserSyncService.new(@user, force: false)
    assert_not service.instance_variable_get(:@force)

    service = UserSyncService.new(@user)
    assert_not service.instance_variable_get(:@force)
  end

  test "should sync recently synced series when force is true" do
    # Create a series that was recently synced (should normally be skipped)
    series = Series.create!(
      tvdb_id: 12345,
      name: "Test Series",
      last_synced_at: 1.hour.ago # Recently synced, should normally skip
    )

    # Create user association
    @user.user_series.create!(series: series)

    # Track sync operations
    series_sync_calls = []

    # Mock SeriesSyncService to track sync calls
    original_series_sync_new = SeriesSyncService.method(:new)
    SeriesSyncService.define_singleton_method(:new) do |client|
      mock_series_service = Object.new
      mock_series_service.define_singleton_method(:sync_episodes_for_series) do |series, series_details|
        series_sync_calls << { series: series, details: series_details }
      end
      mock_series_service
    end

    # Mock TvdbClient methods
    mock_client = Object.new
    mock_client.define_singleton_method(:authenticate) { |pin| true }
    mock_client.define_singleton_method(:get_user_favorites) { [ series.tvdb_id ] }

    # Mock TvdbClient.new
    original_client_new = TvdbClient.method(:new)
    TvdbClient.define_singleton_method(:new) { mock_client }

    # Test without force - should skip sync for recently synced series
    service_without_force = UserSyncService.new(@user, force: false)
    series_sync_calls.clear
    service_without_force.call

    assert_equal 0, series_sync_calls.length, "Should not sync recently synced series without force"

    # Test with force - should sync even recently synced series
    service_with_force = UserSyncService.new(@user, force: true)
    series_sync_calls.clear
    service_with_force.call

    assert_equal 1, series_sync_calls.length, "Should sync recently synced series when force is true"
    assert_equal series, series_sync_calls[0][:series]
  ensure
    # Restore original methods
    SeriesSyncService.define_singleton_method(:new, original_series_sync_new) if defined?(original_series_sync_new)
    TvdbClient.define_singleton_method(:new, original_client_new) if defined?(original_client_new)
  end

  test "should always sync new series regardless of force flag" do
    new_series_id = 99999

    # Track sync operations
    series_sync_calls = []
    created_series = []

    # Mock SeriesSyncService
    original_series_sync_new = SeriesSyncService.method(:new)
    SeriesSyncService.define_singleton_method(:new) do |client|
      mock_series_service = Object.new
      mock_series_service.define_singleton_method(:sync_episodes_for_series) do |series, series_details|
        series_sync_calls << { series: series, details: series_details }
      end
      mock_series_service
    end

    # Mock TvdbClient methods
    mock_client = Object.new
    mock_client.define_singleton_method(:authenticate) { |pin| true }
    mock_client.define_singleton_method(:get_user_favorites) { [ new_series_id ] }
    mock_client.define_singleton_method(:get_series_details) do |tvdb_id|
      { "name" => "New Test Series", "remoteIds" => [] }
    end

    # Mock TvdbClient.new
    original_client_new = TvdbClient.method(:new)
    TvdbClient.define_singleton_method(:new) { mock_client }

    # Test with force: false - should still create and sync new series
    service_without_force = UserSyncService.new(@user, force: false)
    series_sync_calls.clear
    service_without_force.call

    assert_equal 1, series_sync_calls.length, "Should sync new series even without force"

    # Clean up created series
    Series.find_by(tvdb_id: new_series_id)&.destroy

    # Test with force: true - should also create and sync new series
    service_with_force = UserSyncService.new(@user, force: true)
    series_sync_calls.clear
    service_with_force.call

    assert_equal 1, series_sync_calls.length, "Should sync new series with force"
  ensure
    # Clean up any created series
    Series.find_by(tvdb_id: new_series_id)&.destroy

    # Restore original methods
    SeriesSyncService.define_singleton_method(:new, original_series_sync_new) if defined?(original_series_sync_new)
    TvdbClient.define_singleton_method(:new, original_client_new) if defined?(original_client_new)
  end

  test "should handle API errors gracefully when force is used" do
    # Create a series for testing
    series = Series.create!(
      tvdb_id: 12346,
      name: "Error Test Series",
      last_synced_at: 1.hour.ago
    )
    @user.user_series.create!(series: series)

    # Mock TvdbClient to raise error
    mock_client = Object.new
    mock_client.define_singleton_method(:authenticate) { |pin| true }
    mock_client.define_singleton_method(:get_user_favorites) { raise StandardError.new("API Error") }

    original_client_new = TvdbClient.method(:new)
    TvdbClient.define_singleton_method(:new) { mock_client }

    # Should handle error gracefully even with force
    service = UserSyncService.new(@user, force: true)

    assert_raises(StandardError) do
      service.call
    end
  ensure
    TvdbClient.define_singleton_method(:new, original_client_new) if defined?(original_client_new)
  end

  test "should mark user as synced after successful force sync" do
    # Mock minimal successful sync
    mock_client = Object.new
    mock_client.define_singleton_method(:authenticate) { |pin| true }
    mock_client.define_singleton_method(:get_user_favorites) { [] } # No favorites for simplicity

    original_client_new = TvdbClient.method(:new)
    TvdbClient.define_singleton_method(:new) { mock_client }

    original_last_synced = @user.last_synced_at

    service = UserSyncService.new(@user, force: true)
    service.call

    @user.reload
    assert @user.last_synced_at > original_last_synced, "User should be marked as synced after force sync"
  ensure
    TvdbClient.define_singleton_method(:new, original_client_new) if defined?(original_client_new)
  end
end
