require "test_helper"

class SeriesTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(pin: "series_test_#{rand(100000..999999)}")
    @tvdb_id = rand(100000..999999)
    @series = Series.new(
      tvdb_id: @tvdb_id,
      name: "Test Series",
      imdb_id: "tt1234567"
    )
  end

  test "should be valid with valid attributes" do
    assert @series.valid?
  end

  test "should require tvdb_id" do
    @series.tvdb_id = nil
    assert_not @series.valid?
    assert_includes @series.errors[:tvdb_id], "can't be blank"
  end

  test "should require name" do
    @series.name = nil
    assert_not @series.valid?
    assert_includes @series.errors[:name], "can't be blank"
  end

  test "should require unique tvdb_id globally" do
    @series.save!
    duplicate_series = Series.new(
      tvdb_id: @tvdb_id,
      name: "Another Series"
    )
    assert_not duplicate_series.valid?
    assert_includes duplicate_series.errors[:tvdb_id], "has already been taken"
  end

  test "should not allow same tvdb_id for different series" do
    @series.save!
    other_series = Series.new(
      tvdb_id: @tvdb_id,
      name: "Same TVDB ID Different Series"
    )
    assert_not other_series.valid?
  end

  test "should have many users through user_series" do
    assert_respond_to @series, :users
    assert_respond_to @series, :user_series
  end

  test "should have many episodes" do
    assert_respond_to @series, :episodes
  end

  test "should allow multiple users to have same series" do
    @series.save!
    @user.user_series.create!(series: @series)

    other_user = User.create!(pin: "other_#{rand(100000..999999)}")
    other_user.user_series.create!(series: @series)

    assert_includes @series.users, @user
    assert_includes @series.users, other_user
    assert_equal 2, @series.users.count
  end

  test "imdb_url should return correct URL with imdb_id" do
    expected_url = "https://www.imdb.com/title/tt1234567/"
    assert_equal expected_url, @series.imdb_url
  end

  test "imdb_url should return nil without imdb_id" do
    @series.imdb_id = nil
    assert_nil @series.imdb_url
  end

  test "imdb_url should return nil with blank imdb_id" do
    @series.imdb_id = ""
    assert_nil @series.imdb_url
  end

  test "needs_sync? should return true when last_synced_at is nil" do
    @series.last_synced_at = nil
    assert @series.needs_sync?
  end

  test "needs_sync? should return true when last_synced_at is older than 12 hours" do
    @series.last_synced_at = 13.hours.ago
    assert @series.needs_sync?
  end

  test "needs_sync? should return false when last_synced_at is within 12 hours" do
    @series.last_synced_at = 11.hours.ago
    assert_not @series.needs_sync?
  end

  test "mark_as_synced! should update last_synced_at to current time" do
    @series.save!
    freeze_time = Time.current
    travel_to freeze_time do
      @series.mark_as_synced!
      assert_in_delta freeze_time.to_f, @series.reload.last_synced_at.to_f, 1.0
    end
  end
end
