require "test_helper"

class EpisodeTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(pin: "123456")
    @series = Series.create!(
      user: @user,
      tvdb_id: 123,
      name: "Test Series"
    )
    @episode = Episode.new(
      series: @series,
      title: "Test Episode",
      season_number: 1,
      episode_number: 5,
      air_date: Date.current + 1.day
    )
  end

  test "should be valid with valid attributes" do
    assert @episode.valid?
  end

  test "should require title" do
    @episode.title = nil
    assert_not @episode.valid?
    assert_includes @episode.errors[:title], "can't be blank"
  end

  test "should require season_number" do
    @episode.season_number = nil
    assert_not @episode.valid?
    assert_includes @episode.errors[:season_number], "can't be blank"
  end

  test "should require positive season_number" do
    @episode.season_number = 0
    assert_not @episode.valid?
    assert_includes @episode.errors[:season_number], "must be greater than 0"
  end

  test "should require episode_number" do
    @episode.episode_number = nil
    assert_not @episode.valid?
    assert_includes @episode.errors[:episode_number], "can't be blank"
  end

  test "should require positive episode_number" do
    @episode.episode_number = 0
    assert_not @episode.valid?
    assert_includes @episode.errors[:episode_number], "must be greater than 0"
  end

  test "should require air_date" do
    @episode.air_date = nil
    assert_not @episode.valid?
    assert_includes @episode.errors[:air_date], "can't be blank"
  end

  test "should belong to series" do
    assert_respond_to @episode, :series
    assert_equal @series, @episode.series
  end

  test "should have user through series" do
    assert_respond_to @episode, :user
    assert_equal @user, @episode.user
  end

  test "episode_code should format correctly with single digits" do
    @episode.season_number = 1
    @episode.episode_number = 5
    assert_equal "S01E05", @episode.episode_code
  end

  test "episode_code should format correctly with double digits" do
    @episode.season_number = 12
    @episode.episode_number = 25
    assert_equal "S12E25", @episode.episode_code
  end

  test "full_title should return series name" do
    expected = "Test Series"
    assert_equal expected, @episode.full_title
  end

  test "full_title should include season finale text" do
    @episode.is_season_finale = true
    expected = "Test Series - Season Finale"
    assert_equal expected, @episode.full_title
  end

  test "location_text should format correctly" do
    expected = "Test Episode - (S01E05)"
    assert_equal expected, @episode.location_text
  end

  test "upcoming scope should return future episodes" do
    future_episode = Episode.create!(
      series: @series,
      title: "Future Episode",
      season_number: 1,
      episode_number: 1,
      air_date: Date.current + 1.day
    )
    
    past_episode = Episode.create!(
      series: @series,
      title: "Past Episode",
      season_number: 1,
      episode_number: 2,
      air_date: Date.current - 1.day
    )

    upcoming_episodes = Episode.upcoming
    assert_includes upcoming_episodes, future_episode
    assert_not_includes upcoming_episodes, past_episode
  end

  test "aired scope should return past episodes" do
    future_episode = Episode.create!(
      series: @series,
      title: "Future Episode",
      season_number: 1,
      episode_number: 1,
      air_date: Date.current + 1.day
    )
    
    past_episode = Episode.create!(
      series: @series,
      title: "Past Episode",
      season_number: 1,
      episode_number: 2,
      air_date: Date.current - 1.day
    )

    aired_episodes = Episode.aired
    assert_includes aired_episodes, past_episode
    assert_not_includes aired_episodes, future_episode
  end
end
