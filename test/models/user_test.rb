require "test_helper"

class UserTest < ActiveSupport::TestCase
  def setup
    @user = build(:user)
  end

  test "should be valid with valid attributes" do
    assert @user.valid?
  end

  test "should require pin" do
    @user.pin = nil
    assert_not @user.valid?
    assert_includes @user.errors[:pin], "can't be blank"
  end

  test "should require unique pin" do
    pin = "unique_test_#{rand(100000..999999)}"
    existing_user = create(:user, pin: pin)
    duplicate_user = User.new(pin: pin)
    assert_not duplicate_user.valid?
    assert_includes duplicate_user.errors[:pin], "has already been taken"
  end

  test "should have many series" do
    assert_respond_to @user, :series
  end

  test "should have many episodes through series" do
    assert_respond_to @user, :episodes
  end

  test "needs_sync? should return true for new user" do
    user = build(:user, :needs_sync)
    assert user.needs_sync?
  end

  test "needs_sync? should return true for user not synced in over an hour" do
    user = create(:user, :stale_sync)
    assert user.needs_sync?
  end

  test "needs_sync? should return false for recently synced user" do
    user = create(:user, :recently_synced)
    assert_not user.needs_sync?
  end

  test "mark_as_synced! should update last_synced_at" do
    user = create(:user)
    before_time = Time.current

    user.mark_as_synced!

    # Just ensure it was updated to something recent
    assert user.reload.last_synced_at >= before_time
    assert user.reload.last_synced_at <= Time.current
  end
end
