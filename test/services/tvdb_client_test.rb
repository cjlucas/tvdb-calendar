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

  test "should authenticate successfully" do
    mock_response = {
      "data" => { "token" => "test_token" }
    }
    
    TvdbClient.stub_any_instance(:post, OpenStruct.new(success?: true, parsed_response: mock_response)) do
      token = @client.authenticate("123456")
      assert_equal "test_token", token
      assert_equal "test_token", @client.instance_variable_get(:@token)
    end
  end

  test "should raise error on authentication failure" do
    mock_response = {
      "message" => "Invalid PIN"
    }
    
    TvdbClient.stub_any_instance(:post, OpenStruct.new(success?: false, parsed_response: mock_response)) do
      assert_raises RuntimeError, "Authentication failed: Invalid PIN" do
        @client.authenticate("invalid")
      end
    end
  end

  test "should get user favorites" do
    @client.instance_variable_set(:@token, "test_token")
    
    mock_response = {
      "data" => [
        { "id" => 123, "name" => "Series 1" },
        { "id" => 456, "name" => "Series 2" }
      ]
    }
    
    TvdbClient.stub_any_instance(:get, OpenStruct.new(success?: true, parsed_response: mock_response)) do
      favorites = @client.get_user_favorites
      assert_equal 2, favorites.length
      assert_equal 123, favorites.first["id"]
    end
  end

  test "should raise error when not authenticated for favorites" do
    assert_raises RuntimeError, "Not authenticated" do
      @client.get_user_favorites
    end
  end

  test "should get series details" do
    @client.instance_variable_set(:@token, "test_token")
    
    mock_response = {
      "data" => {
        "id" => 123,
        "name" => "Test Series",
        "remoteIds" => [
          { "sourceName" => "IMDB", "id" => "tt1234567" }
        ]
      }
    }
    
    TvdbClient.stub_any_instance(:get, OpenStruct.new(success?: true, parsed_response: mock_response)) do
      details = @client.get_series_details(123)
      assert_equal "Test Series", details["name"]
      assert_equal "tt1234567", details["remoteIds"].first["id"]
    end
  end

  test "should get series episodes" do
    @client.instance_variable_set(:@token, "test_token")
    
    mock_response = {
      "data" => {
        "episodes" => [
          {
            "name" => "Episode 1",
            "seasonNumber" => 1,
            "number" => 1,
            "aired" => "2023-01-01"
          }
        ],
        "links" => { "total_pages" => 1 }
      }
    }
    
    TvdbClient.stub_any_instance(:get, OpenStruct.new(success?: true, parsed_response: mock_response)) do
      episodes = @client.get_series_episodes(123)
      assert_equal 1, episodes.length
      assert_equal "Episode 1", episodes.first["name"]
    end
  end
end