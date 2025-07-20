require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get root_path
    assert_response :success
    assert_select "h1", "TVDB Calendar Generator"
    assert_select "form"
    assert_select "input[name='user[pin]']"
  end

  test "should assign new user instance" do
    get root_path
    assert assigns(:user)
    assert assigns(:user).new_record?
  end
end