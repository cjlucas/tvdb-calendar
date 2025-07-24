require "test_helper"

class UserSyncIndividualJobTest < ActiveJob::TestCase
  def setup
    @user = users(:one)
  end

  test "should define InvalidPinError exception class" do
    assert_not_nil InvalidPinError
    assert InvalidPinError < StandardError
  end

  test "should handle user not found gracefully" do
    # User not found should be caught by the general rescue clause
    # and not raise an exception, but would broadcast an error message
    assert_nothing_raised do
      UserSyncIndividualJob.perform_now("nonexistent_pin")
    end
  end

  test "should handle InvalidPinError in job rescue clause" do
    # Verify the rescue clause for InvalidPinError exists
    job_source = File.read(Rails.root.join("app/jobs/user_sync_individual_job.rb"))
    assert_includes job_source, "rescue InvalidPinError"
    assert_includes job_source, '"PIN Invalid"'
  end

  test "should pass force parameter to UserSyncService" do
    sync_service_calls = []

    # Mock UserSyncService.new to capture the force parameter
    original_new = UserSyncService.method(:new)
    UserSyncService.define_singleton_method(:new) do |user, force: false|
      sync_service_calls << { user: user, force: force }

      # Return a mock service that responds to call
      mock_service = Object.new
      mock_service.define_singleton_method(:call) { true }
      mock_service
    end

    # Test with force: true
    UserSyncIndividualJob.perform_now(@user.pin, force: true)
    assert_equal 1, sync_service_calls.length
    assert_equal @user, sync_service_calls[0][:user]
    assert_equal true, sync_service_calls[0][:force]

    # Reset and test with force: false
    sync_service_calls.clear
    UserSyncIndividualJob.perform_now(@user.pin, force: false)
    assert_equal 1, sync_service_calls.length
    assert_equal false, sync_service_calls[0][:force]

    # Reset and test with default (no force parameter)
    sync_service_calls.clear
    UserSyncIndividualJob.perform_now(@user.pin)
    assert_equal 1, sync_service_calls.length
    assert_equal false, sync_service_calls[0][:force]
  ensure
    # Restore original method
    UserSyncService.define_singleton_method(:new, original_new)
  end

  test "should handle sync service errors gracefully" do
    # Mock UserSyncService to raise an error
    original_new = UserSyncService.method(:new)
    UserSyncService.define_singleton_method(:new) do |user, force: false|
      mock_service = Object.new
      mock_service.define_singleton_method(:call) { raise StandardError.new("Sync failed") }
      mock_service
    end

    # Should not raise error, should broadcast error message instead
    assert_nothing_raised do
      UserSyncIndividualJob.perform_now(@user.pin, force: true)
    end
  ensure
    # Restore original method
    UserSyncService.define_singleton_method(:new, original_new)
  end
end
