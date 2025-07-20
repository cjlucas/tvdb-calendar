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
    assert_includes ics_content, "X-WR-CALNAME:TV Shows - #{@user.pin}"
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
    assert_includes ics_content, "LOCATION:Test Episode - (S01E05)"

    # Check date format
    date_str = (@episode.air_date).strftime("%Y%m%d")
    assert_includes ics_content, "DTSTART;VALUE=DATE:#{date_str}"
    assert_includes ics_content, "DTEND;VALUE=DATE:#{date_str}"
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
end
