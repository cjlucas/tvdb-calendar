require "test_helper"

class CalendarControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = User.create!(pin: "calendar_test_#{rand(100000..999999)}")
    @series = Series.create!(
      tvdb_id: rand(100000..999999),
      name: "Test Series",
      imdb_id: "tt1234567"
    )
    @user.user_series.create!(series: @series)
    @episode = Episode.create!(
      series: @series,
      title: "Test Episode",
      season_number: 1,
      episode_number: 1,
      air_date: Date.current + 1.day
    )
  end

  test "should generate ICS calendar" do
    get user_calendar_path(@user.pin)

    assert_response :success
    assert_equal "text/calendar; charset=utf-8", response.content_type

    calendar_content = response.body
    assert_includes calendar_content, "BEGIN:VCALENDAR"
    assert_includes calendar_content, "END:VCALENDAR"
    assert_includes calendar_content, "Test Series"
    assert_includes calendar_content, "Test Episode - (01x01)"
  end

  test "should serve ICS with proper filename" do
    get user_calendar_path(@user.pin), headers: { "Accept" => "text/calendar" }

    assert_response :success
    assert_includes response.headers["Content-Disposition"], "tvdb-calendar-#{@user.pin}.ics"
  end

  test "should return 404 for non-existent user" do
    get user_calendar_path("nonexistent")

    assert_response :not_found
    assert_equal "User not found", response.body
  end

  test "should handle empty episode list" do
    @episode.destroy

    get user_calendar_path(@user.pin)

    assert_response :success
    calendar_content = response.body
    assert_includes calendar_content, "BEGIN:VCALENDAR"
    assert_includes calendar_content, "END:VCALENDAR"
    # Should not include any VEVENT blocks
    assert_not_includes calendar_content, "BEGIN:VEVENT"
  end
end
