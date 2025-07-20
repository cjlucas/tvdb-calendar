require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get root_path
    assert_response :success
    assert_select "h1", "TVDB Calendar Generator"
    assert_select "form"
    assert_select "input[name='user[pin]']"
  end

  test "should render form for user input" do
    get root_path
    assert_response :success
    # Test that the form is properly rendered for user interaction
    assert_select "input[name='user[pin]'][placeholder]"
    assert_select "input[type='submit']"
  end
end
