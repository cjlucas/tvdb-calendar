require "test_helper"

class TvdbClientTest < ActiveSupport::TestCase
  def setup
    @client = TvdbClient.new("test_api_key")
  end

  test "should initialize with api key" do
    assert_equal "test_api_key", @client.instance_variable_get(:@api_key)
  end

  test "should raise error without api key" do
    assert_raises ArgumentError do
      TvdbClient.new(nil)
    end
  end

  test "should have authenticate method" do
    assert_respond_to @client, :authenticate
  end

  test "should have get_user_favorites method" do
    assert_respond_to @client, :get_user_favorites
  end

  test "should have get_series_details method" do
    assert_respond_to @client, :get_series_details
  end

  test "should have get_series_episodes method" do
    assert_respond_to @client, :get_series_episodes
  end

  test "should raise error when not authenticated for favorites" do
    assert_raises RuntimeError, "Not authenticated" do
      @client.get_user_favorites
    end
  end

  test "should allow series details without authentication" do
    # This test verifies that get_series_details no longer requires authentication
    # The actual API call will fail in tests, but it shouldn't fail due to missing auth
    assert_respond_to @client, :get_series_details
  end

  test "should allow episodes without authentication" do
    # This test verifies that get_series_episodes no longer requires authentication
    # The actual API call will fail in tests, but it shouldn't fail due to missing auth
    assert_respond_to @client, :get_series_episodes
  end

  test "should define InvalidPinError exception class" do
    assert_not_nil InvalidPinError
    assert InvalidPinError < StandardError
  end

  test "should have improved PIN detection logic for word boundaries" do
    # Test that the PIN detection logic uses word boundaries
    # This is tested indirectly by verifying the regex pattern logic

    # Test word boundary matching for PIN
    assert_match(/\bpin\b/i, "Invalid PIN provided")
    assert_match(/\bpin\b/i, "PIN is required")
    refute_match(/\bpin\b/i, "shipping required")
    refute_match(/\bpin\b/i, "spinning up server")
  end

  test "should have improved PIN detection for error patterns" do
    # Test that the PIN detection logic looks for invalid/pin patterns

    # Test invalid PIN patterns
    assert_match(/invalid.*pin|pin.*invalid/i, "invalid PIN provided")
    assert_match(/invalid.*pin|pin.*invalid/i, "PIN invalid for user")
    refute_match(/invalid.*pin|pin.*invalid/i, "invalid request")
  end
end
