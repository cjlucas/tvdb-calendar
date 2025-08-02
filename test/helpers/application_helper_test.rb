require "test_helper"

class ApplicationHelperTest < ActionView::TestCase
  test "app_version returns APP_VERSION environment variable" do
    # Test when APP_VERSION is not set
    ENV.delete("APP_VERSION")
    assert_nil app_version

    # Test when APP_VERSION is set
    ENV["APP_VERSION"] = "abc123"
    assert_equal "abc123", app_version

    # Clean up
    ENV.delete("APP_VERSION")
  end
end
