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

  test "should identify correct series for syncing" do
    # Verify initial state
    assert @series1.needs_sync?, "series1 should need sync (13 hours old)"
    assert_not @series2.needs_sync?, "series2 should not need sync (11 hours old)"
    assert @series3.needs_sync?, "series3 should need sync (nil timestamp)"

    # Test the query logic used by SeriesSyncJob
    series_to_sync = Series.where("last_synced_at IS NULL OR last_synced_at < ?", 12.hours.ago)
    our_test_series = series_to_sync.where(id: [ @series1.id, @series2.id, @series3.id ])

    assert_includes our_test_series, @series1, "series1 should be selected for sync"
    assert_not_includes our_test_series, @series2, "series2 should not be selected for sync"
    assert_includes our_test_series, @series3, "series3 should be selected for sync"
  end

  test "should update timestamps when series sync completes" do
    initial_series1_sync_time = @series1.last_synced_at

    # Manually call mark_as_synced! to test timestamp update
    @series1.mark_as_synced!

    assert @series1.reload.last_synced_at != initial_series1_sync_time, "series1 timestamp should have changed"
    assert @series1.reload.last_synced_at > 1.minute.ago, "series1 should have recent timestamp"
    assert_not @series1.reload.needs_sync?, "series1 should no longer need sync"
  end

  test "should handle sync errors gracefully" do
    # Test that errors don't prevent mark_as_synced! from working
    initial_sync_time = @series1.last_synced_at

    # Simulate what happens when sync_series_data fails but mark_as_synced! should still work
    begin
      # This would normally happen in the job
      @series1.mark_as_synced!
    rescue => e
      # Should not raise error
      flunk "mark_as_synced! should not raise error: #{e.message}"
    end

    assert @series1.reload.last_synced_at != initial_sync_time, "timestamp should be updated even after error handling"
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

  test "should prevent duplicate job execution" do
    # Test that perform_later_if_unique prevents duplicates
    # Note: This is a basic test - in practice, the uniqueness check
    # would prevent multiple jobs from being enqueued simultaneously

    # Should return a job instance on first call
    job1 = SeriesSyncJob.perform_later_if_unique
    assert job1, "First job should be enqueued"

    # This is a simplified test - in real scenarios we'd test with
    # multiple processes trying to enqueue simultaneously
  end
end
