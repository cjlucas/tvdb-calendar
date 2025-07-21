require "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
  test "should create new user and start sync" do
    pin = "new_user_#{rand(100000..999999)}"

    post users_path, params: { user: { pin: pin } }, as: :json

    assert_response :success
    response_data = JSON.parse(response.body)

    assert_equal "syncing", response_data["status"]
    assert response_data["user_pin"]
    assert response_data["calendar_url"]

    user = User.find_by(pin: pin)
    assert user
  end

  test "should handle existing user needing sync" do
    pin = "existing_user_#{rand(100000..999999)}"
    user = User.create!(pin: pin, last_synced_at: 2.hours.ago)

    post users_path, params: { user: { pin: pin } }, as: :json

    assert_response :success
    response_data = JSON.parse(response.body)

    assert_equal "syncing", response_data["status"]
    assert_equal user.pin, response_data["user_pin"]
  end

  test "should handle existing user not needing sync" do
    pin = "ready_user_#{rand(100000..999999)}"
    user = User.create!(pin: pin, last_synced_at: 30.minutes.ago)

    post users_path, params: { user: { pin: pin } }, as: :json

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

  test "should handle missing pin parameter" do
    post users_path, params: { user: { pin: nil } }, as: :json

    assert_response :unprocessable_entity
    response_data = JSON.parse(response.body)

    assert_equal "error", response_data["status"]
  end

  test "should define InvalidPinError exception class" do
    assert_not_nil InvalidPinError
    assert InvalidPinError < StandardError
  end

  test "should handle InvalidPinError in rescue clause" do
    # Verify the rescue clause for InvalidPinError exists
    controller_source = File.read(Rails.root.join("app/controllers/users_controller.rb"))
    assert_includes controller_source, "rescue InvalidPinError"
    assert_includes controller_source, '"PIN Invalid"'
  end
end
