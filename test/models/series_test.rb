require "test_helper"

class SeriesTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(pin: "series_test_#{rand(100000..999999)}")
    @series = Series.new(
      user: @user,
      tvdb_id: 123,
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

  test "should require unique tvdb_id per user" do
    @series.save!
    duplicate_series = Series.new(
      user: @user,
      tvdb_id: 123,
      name: "Another Series"
    )
    assert_not duplicate_series.valid?
    assert_includes duplicate_series.errors[:tvdb_id], "has already been taken"
  end

  test "should allow same tvdb_id for different users" do
    @series.save!
    other_user = User.create!(pin: "other_series_#{rand(100000..999999)}")
    other_series = Series.new(
      user: other_user,
      tvdb_id: 123,
      name: "Same TVDB ID Different User"
    )
    assert other_series.valid?
  end

  test "should belong to user" do
    assert_respond_to @series, :user
    assert_equal @user, @series.user
  end

  test "should have many episodes" do
    assert_respond_to @series, :episodes
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
end
