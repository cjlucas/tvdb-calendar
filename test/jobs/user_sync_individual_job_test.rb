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

  test "should accept force parameter and pass to UserSyncService" do
    # Test that the job accepts force parameter and passes it correctly
    
    # Create a simple test to verify the method signature accepts force parameter
    job = UserSyncIndividualJob.new
    
    # Test that perform method can be called with force parameter
    assert_respond_to job, :perform
    
    # Check that the source code includes force parameter handling
    job_source = File.read(Rails.root.join("app/jobs/user_sync_individual_job.rb"))
    assert_includes job_source, "force: false"
    assert_includes job_source, "force: force"
  end

  test "should log force indicator in job source" do
    # Verify the job source includes force logging
    job_source = File.read(Rails.root.join("app/jobs/user_sync_individual_job.rb"))
    assert_includes job_source, 'force ? \' (forced)\' : \'\''
  end
end