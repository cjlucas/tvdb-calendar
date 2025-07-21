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

  test "should raise error when not authenticated for series details" do
    assert_raises RuntimeError, "Not authenticated" do
      @client.get_series_details(123)
    end
  end

  test "should raise error when not authenticated for episodes" do
    assert_raises RuntimeError, "Not authenticated" do
      @client.get_series_episodes(123)
    end
  end

  test "should define InvalidPinError exception class" do
    assert_not_nil InvalidPinError
    assert InvalidPinError < StandardError
  end
end
