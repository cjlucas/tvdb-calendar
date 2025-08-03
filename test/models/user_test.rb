require "test_helper"

class UserTest < ActiveSupport::TestCase
  def setup
    @user = User.new(pin: "user_test_#{rand(100000..999999)}", uuid: SecureRandom.uuid_v7)
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
    existing_user = User.create!(pin: pin, uuid: SecureRandom.uuid_v7)
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
    user = User.new(pin: "new_user_#{rand(100000..999999)}")
    assert user.needs_sync?
  end

  test "needs_sync? should return true for user not synced in over an hour" do
    user = User.create!(pin: "old_sync_#{rand(100000..999999)}", uuid: SecureRandom.uuid_v7, last_synced_at: 2.hours.ago)
    assert user.needs_sync?
  end

  test "needs_sync? should return false for recently synced user" do
    user = User.create!(pin: "recent_sync_#{rand(100000..999999)}", uuid: SecureRandom.uuid_v7, last_synced_at: 30.minutes.ago)
    assert_not user.needs_sync?
  end

  test "mark_as_synced! should update last_synced_at" do
    user = User.create!(pin: "mark_sync_#{rand(100000..999999)}", uuid: SecureRandom.uuid_v7)
    before_time = Time.current

    user.mark_as_synced!

    # Just ensure it was updated to something recent
    assert user.reload.last_synced_at >= before_time
    assert user.reload.last_synced_at <= Time.current
  end
end
