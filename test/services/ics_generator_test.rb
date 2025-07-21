require "test_helper"

class IcsGeneratorTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(pin: "ics_test_#{rand(100000..999999)}")
    @series = Series.create!(
      user: @user,
      tvdb_id: 123,
      name: "Test Series",
      imdb_id: "tt1234567"
    )
    @episode = Episode.create!(
      series: @series,
      title: "Test Episode",
      season_number: 1,
      episode_number: 5,
      air_date: Date.current + 1.day,
      is_season_finale: false
    )
    @generator = IcsGenerator.new(@user)
  end

  test "should generate valid ICS calendar" do
    ics_content = @generator.generate

    # Check basic ICS structure
    assert_includes ics_content, "BEGIN:VCALENDAR"
    assert_includes ics_content, "END:VCALENDAR"
    assert_includes ics_content, "VERSION:2.0"
    assert_includes ics_content, "PRODID:-//TVDB Calendar//NONSGML v1.0//EN"

    # Check calendar metadata
    assert_includes ics_content, "X-WR-CALNAME:TV Shows"
    assert_includes ics_content, "X-WR-CALDESC:Upcoming episodes for your favorite TV shows from TheTVDB"
  end

  test "should include upcoming episodes only" do
    past_episode = Episode.create!(
      series: @series,
      title: "Past Episode",
      season_number: 1,
      episode_number: 1,
      air_date: Date.current - 1.day
    )

    ics_content = @generator.generate

    assert_includes ics_content, "Test Episode"
    assert_not_includes ics_content, "Past Episode"
  end

  test "should format episode events correctly" do
    ics_content = @generator.generate

    # Check event structure
    assert_includes ics_content, "BEGIN:VEVENT"
    assert_includes ics_content, "END:VEVENT"

    # Check event fields
    assert_includes ics_content, "SUMMARY:Test Series"
    assert_includes ics_content, "LOCATION:Test Episode - (01x05)"

    # Check date format
    date_str = (@episode.air_date).strftime("%Y%m%d")
    date_end = (@episode.air_date + 1.day).strftime("%Y%m%d")
    assert_includes ics_content, "DTSTART;VALUE=DATE:#{date_str}"
    assert_includes ics_content, "DTEND;VALUE=DATE:#{date_end}"
  end

  test "should include IMDB URL when available" do
    ics_content = @generator.generate

    assert_includes ics_content, "DESCRIPTION:Watch on IMDB: https://www.imdb.com/title/tt1234567/"
    assert_includes ics_content, "URL:https://www.imdb.com/title/tt1234567/"
  end

  test "should handle series without IMDB ID" do
    @series.update!(imdb_id: nil)

    ics_content = @generator.generate

    assert_not_includes ics_content, "DESCRIPTION:"
    assert_not_includes ics_content, "URL:"
  end

  test "should handle season finale episodes" do
    @episode.update!(is_season_finale: true)

    ics_content = @generator.generate

    assert_includes ics_content, "SUMMARY:Test Series - Season Finale"
  end

  test "should escape special characters" do
    @episode.update!(title: "Episode, with; special \"characters\"")

    ics_content = @generator.generate

    assert_includes ics_content, "Episode\\, with\\; special \\\"characters\\\""
  end

  test "should handle empty episode list" do
    @episode.destroy

    ics_content = @generator.generate

    assert_includes ics_content, "BEGIN:VCALENDAR"
    assert_includes ics_content, "END:VCALENDAR"
    assert_not_includes ics_content, "BEGIN:VEVENT"
  end

  test "should generate unique UIDs for episodes" do
    second_episode = Episode.create!(
      series: @series,
      title: "Another Episode",
      season_number: 1,
      episode_number: 6,
      air_date: Date.current + 2.days
    )

    ics_content = @generator.generate

    # Should contain two unique UIDs
    uid_matches = ics_content.scan(/UID:episode-\d+-\d+@tvdbcalendar\.com/)
    assert_equal 2, uid_matches.length
    assert_equal uid_matches.uniq.length, uid_matches.length
  end

  test "should include timezone definition" do
    ics_content = @generator.generate

    assert_includes ics_content, "BEGIN:VTIMEZONE"
    assert_includes ics_content, "TZID:America/New_York"
    assert_includes ics_content, "END:VTIMEZONE"
  end

  test "should generate timed events when air_datetime_utc is present" do
    # Set air time to 8 PM UTC (4 PM EDT in summer)
    air_time_utc = Time.parse("2025-07-21 20:00:00 UTC")
    @episode.update!(
      air_datetime_utc: air_time_utc,
      runtime_minutes: 60
    )

    ics_content = @generator.generate

    # Should use TZID format instead of VALUE=DATE
    assert_includes ics_content, "DTSTART;TZID=America/New_York:20250721T160000"
    assert_includes ics_content, "DTEND;TZID=America/New_York:20250721T170000"

    # Should not include VALUE=DATE format
    assert_not_includes ics_content, "VALUE=DATE"
  end

  test "should fall back to all-day event when no air_datetime_utc" do
    @episode.update!(air_datetime_utc: nil)

    ics_content = @generator.generate

    # Should use VALUE=DATE format
    date_str = @episode.air_date.strftime("%Y%m%d")
    date_end = (@episode.air_date + 1.day).strftime("%Y%m%d")
    assert_includes ics_content, "DTSTART;VALUE=DATE:#{date_str}"
    assert_includes ics_content, "DTEND;VALUE=DATE:#{date_end}"

    # Should not include TZID format
    assert_not_includes ics_content, "TZID=America/New_York"
  end

  test "should use default duration when runtime_minutes is nil" do
    air_time_utc = Time.parse("2025-07-21 20:00:00 UTC")
    @episode.update!(
      air_datetime_utc: air_time_utc,
      runtime_minutes: nil
    )

    ics_content = @generator.generate

    # Should default to 30-minute duration
    assert_includes ics_content, "DTSTART;TZID=America/New_York:20250721T160000"
    assert_includes ics_content, "DTEND;TZID=America/New_York:20250721T163000"
  end

  test "should handle winter timezone (EST) correctly" do
    # Set air time in winter (EST, UTC-5) - use future date
    future_winter_date = Date.parse("2026-01-15")
    air_time_utc = Time.parse("2026-01-15 21:00:00 UTC")
    @episode.update!(
      air_datetime_utc: air_time_utc,
      runtime_minutes: 30,
      air_date: future_winter_date
    )

    ics_content = @generator.generate

    # 9 PM UTC in winter = 4 PM EST
    assert_includes ics_content, "DTSTART;TZID=America/New_York:20260115T160000"
    assert_includes ics_content, "DTEND;TZID=America/New_York:20260115T163000"
  end

  test "should handle mixed episodes with and without air times" do
    # Episode with specific time
    timed_episode = Episode.create!(
      series: @series,
      title: "Timed Episode",
      season_number: 1,
      episode_number: 10,
      air_date: Date.current + 2.days,
      air_datetime_utc: Time.parse("2025-07-21 20:00:00 UTC"),
      runtime_minutes: 45
    )

    # Episode without specific time (all-day)
    allday_episode = Episode.create!(
      series: @series,
      title: "All Day Episode",
      season_number: 1,
      episode_number: 11,
      air_date: Date.current + 3.days,
      air_datetime_utc: nil
    )

    ics_content = @generator.generate

    # Should contain both timed and all-day formats
    assert_includes ics_content, "DTSTART;TZID=America/New_York:"
    assert_includes ics_content, "DTSTART;VALUE=DATE:"
  end

  test "should properly escape timezone info" do
    air_time_utc = Time.parse("2025-07-21 20:00:00 UTC")
    @episode.update!(air_datetime_utc: air_time_utc)

    ics_content = @generator.generate

    # Timezone ID should not be escaped
    assert_includes ics_content, "TZID:America/New_York"
    assert_not_includes ics_content, "TZID:America\\/New_York"
  end
end
