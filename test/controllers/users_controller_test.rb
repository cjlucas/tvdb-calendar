require "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
  test "should create new user and start sync" do
    # Mock the UserSyncService
    UserSyncService.stub_any_instance(:call, nil) do
      post users_path, params: { user: { pin: "123456" } }, as: :json
      
      assert_response :success
      response_data = JSON.parse(response.body)
      
      assert_equal "syncing", response_data["status"]
      assert response_data["user_pin"]
      assert response_data["calendar_url"]
      
      user = User.find_by(pin: "123456")
      assert user
    end
  end

  test "should handle existing user needing sync" do
    user = User.create!(pin: "123456", last_synced_at: 2.hours.ago)
    
    UserSyncService.stub_any_instance(:call, nil) do
      post users_path, params: { user: { pin: "123456" } }, as: :json
      
      assert_response :success
      response_data = JSON.parse(response.body)
      
      assert_equal "syncing", response_data["status"]
      assert_equal user.pin, response_data["user_pin"]
    end
  end

  test "should handle existing user not needing sync" do
    user = User.create!(pin: "123456", last_synced_at: 30.minutes.ago)
    
    post users_path, params: { user: { pin: "123456" } }, as: :json
    
    assert_response :success
    response_data = JSON.parse(response.body)
    
    assert_equal "ready", response_data["status"]
    assert_equal user.pin, response_data["user_pin"]
  end

  test "should handle validation errors" do
    post users_path, params: { user: { pin: "" } }, as: :json
    
    assert_response :unprocessable_entity
    response_data = JSON.parse(response.body)
    
    assert_equal "error", response_data["status"]
    assert response_data["errors"]
  end

  test "should handle sync service errors" do
    UserSyncService.stub_any_instance(:call, -> { raise "API Error" }) do
      post users_path, params: { user: { pin: "123456" } }, as: :json
      
      assert_response :unprocessable_entity
      response_data = JSON.parse(response.body)
      
      assert_equal "error", response_data["status"]
      assert_includes response_data["message"], "Failed to authenticate"
    end
  end
end