require "test_helper"

class EpisodeTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(pin: "episode_test_#{rand(100000..999999)}")
    @series = Series.create!(
      tvdb_id: rand(100000..999999),
      name: "Test Series"
    )
    @user.user_series.create!(series: @series)
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

  test "should require non-negative season_number" do
    @episode.season_number = -1
    assert_not @episode.valid?
    assert_includes @episode.errors[:season_number], "must be greater than or equal to 0"
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

  test "should have users through series" do
    assert_respond_to @episode, :users
    assert_includes @episode.users, @user
  end

  test "episode_code should format correctly with single digits" do
    @episode.season_number = 1
    @episode.episode_number = 5
    assert_equal "01x05", @episode.episode_code
  end

  test "episode_code should format correctly with double digits" do
    @episode.season_number = 12
    @episode.episode_number = 25
    assert_equal "12x25", @episode.episode_code
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
    expected = "Test Episode - (01x05)"
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

  test "should validate runtime_minutes when present" do
    @episode.runtime_minutes = -5
    assert_not @episode.valid?
    assert_includes @episode.errors[:runtime_minutes], "must be greater than 0"

    @episode.runtime_minutes = 30
    assert @episode.valid?

    @episode.runtime_minutes = nil
    assert @episode.valid?
  end

  test "has_specific_air_time? should return false when air_datetime_utc is nil" do
    @episode.air_datetime_utc = nil
    assert_not @episode.has_specific_air_time?
  end

  test "has_specific_air_time? should return true when air_datetime_utc is present" do
    @episode.air_datetime_utc = Time.current.utc
    assert @episode.has_specific_air_time?
  end

  test "air_time_in_timezone should return nil when air_datetime_utc is nil" do
    @episode.air_datetime_utc = nil
    assert_nil @episode.air_time_in_timezone
  end

  test "air_time_in_timezone should convert to target timezone" do
    utc_time = Time.parse("2025-07-21 20:00:00 UTC")
    @episode.air_datetime_utc = utc_time

    ny_time = @episode.air_time_in_timezone("America/New_York")
    assert_equal "16:00", ny_time.strftime("%H:%M") # 8 PM UTC = 4 PM EDT
  end

  test "end_time_in_timezone should return nil when air_datetime_utc is nil" do
    @episode.air_datetime_utc = nil
    @episode.runtime_minutes = 30
    assert_nil @episode.end_time_in_timezone
  end

  test "end_time_in_timezone should return nil when runtime_minutes is nil" do
    @episode.air_datetime_utc = Time.current.utc
    @episode.runtime_minutes = nil
    assert_nil @episode.end_time_in_timezone
  end

  test "end_time_in_timezone should calculate end time correctly" do
    utc_time = Time.parse("2025-07-21 20:00:00 UTC")
    @episode.air_datetime_utc = utc_time
    @episode.runtime_minutes = 60

    end_time = @episode.end_time_in_timezone("America/New_York")
    assert_equal "17:00", end_time.strftime("%H:%M") # 4 PM + 1 hour = 5 PM
  end

  test "runtime_duration should return nil when runtime_minutes is nil" do
    @episode.runtime_minutes = nil
    assert_nil @episode.runtime_duration
  end

  test "runtime_duration should return duration object" do
    @episode.runtime_minutes = 45
    duration = @episode.runtime_duration
    assert_equal 45.minutes, duration
  end

  test "upcoming_with_time scope should filter by air_datetime_utc" do
    future_time = 1.hour.from_now.utc
    past_time = 1.hour.ago.utc

    future_episode = Episode.create!(
      series: @series,
      title: "Future Episode",
      season_number: 1,
      episode_number: 10,
      air_date: Date.current + 1.day,
      air_datetime_utc: future_time
    )

    past_episode = Episode.create!(
      series: @series,
      title: "Past Episode",
      season_number: 1,
      episode_number: 11,
      air_date: Date.current - 1.day,
      air_datetime_utc: past_time
    )

    upcoming_episodes = Episode.upcoming_with_time
    assert_includes upcoming_episodes, future_episode
    assert_not_includes upcoming_episodes, past_episode
  end

  test "aired_with_time scope should filter by air_datetime_utc" do
    future_time = 1.hour.from_now.utc
    past_time = 1.hour.ago.utc

    future_episode = Episode.create!(
      series: @series,
      title: "Future Episode",
      season_number: 1,
      episode_number: 12,
      air_date: Date.current + 1.day,
      air_datetime_utc: future_time
    )

    past_episode = Episode.create!(
      series: @series,
      title: "Past Episode",
      season_number: 1,
      episode_number: 13,
      air_date: Date.current - 1.day,
      air_datetime_utc: past_time
    )

    aired_episodes = Episode.aired_with_time
    assert_includes aired_episodes, past_episode
    assert_not_includes aired_episodes, future_episode
  end
end
