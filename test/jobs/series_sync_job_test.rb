require "test_helper"
require "minitest/mock"

class SeriesSyncJobTest < ActiveJob::TestCase
  def setup
    @user = User.create!(pin: "series_sync_test_#{rand(100000..999999)}")
    @series1 = Series.create!(
      tvdb_id: rand(100000..999999),
      name: "Test Series 1",
      last_synced_at: 13.hours.ago
    )
    @series2 = Series.create!(
      tvdb_id: rand(100000..999999),
      name: "Test Series 2",
      last_synced_at: 11.hours.ago
    )
    @series3 = Series.create!(
      tvdb_id: rand(100000..999999),
      name: "Test Series 3",
      last_synced_at: nil
    )
  end

  test "should only sync series that need syncing" do
    initial_series2_sync_time = @series2.last_synced_at

    # Stub TvdbClient methods without strict expectations for simplicity
    mock_client = Object.new
    def mock_client.authenticate(pin); true; end
    def mock_client.get_series_details(tvdb_id)
      {
        "name" => "Updated Test Series #{tvdb_id}",
        "remoteIds" => [ { "sourceName" => "IMDB", "id" => "tt1234567" } ]
      }
    end

    TvdbClient.stub :new, mock_client do
      SeriesSyncJob.perform_now
    end

    # series1 and series3 should be updated (they need sync)
    # series2 should not be touched (within 12 hours)
    assert @series1.reload.last_synced_at > 13.hours.ago
    assert_equal initial_series2_sync_time.to_i, @series2.reload.last_synced_at.to_i
    assert @series3.reload.last_synced_at.present?
  end

  test "should handle errors gracefully and continue processing" do
    initial_series1_sync_time = @series1.last_synced_at
    series1_tvdb_id = @series1.tvdb_id

    # Mock client that fails for series1 but succeeds for series3
    mock_client = Object.new
    mock_client.define_singleton_method(:authenticate) { |pin| true }
    mock_client.define_singleton_method(:get_series_details) do |tvdb_id|
      if tvdb_id == series1_tvdb_id
        raise StandardError.new("API Error")
      else
        {
          "name" => "Updated Test Series #{tvdb_id}",
          "remoteIds" => []
        }
      end
    end

    TvdbClient.stub :new, mock_client do
      SeriesSyncJob.perform_now
    end

    # series1 should not be updated due to error
    assert_equal initial_series1_sync_time.to_i, @series1.reload.last_synced_at.to_i
    # series3 should still be processed successfully
    assert @series3.reload.last_synced_at.present?
  end

  test "should return early when no users are available for authentication" do
    # Remove all users (delete associations first)
    UserSeries.delete_all
    User.delete_all

    # Job should complete without errors
    assert_nothing_raised do
      SeriesSyncJob.perform_now
    end
  end
end
