require "test_helper"

class CalendarControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = create(:user)
    @series = create(:series)
    @user.user_series.create!(series: @series)
    @episode = create(:episode, series: @series, title: "Test Episode")
  end

  test "should generate ICS calendar" do
    get user_calendar_path(@user.uuid)

    assert_response :success
    assert_equal "text/calendar; charset=utf-8", response.content_type

    calendar_content = response.body
    assert_includes calendar_content, "BEGIN:VCALENDAR"
    assert_includes calendar_content, "END:VCALENDAR"
    assert_includes calendar_content, "Test Series"
    assert_includes calendar_content, "Test Episode (01x01)"
  end

  test "should serve ICS with proper filename" do
    get user_calendar_path(@user.uuid), headers: { "Accept" => "text/calendar" }

    assert_response :success
    assert_includes response.headers["Content-Disposition"], "tvdb-calendar-#{@user.uuid}.ics"
  end

  test "should return 404 for non-existent user" do
    get user_calendar_path("nonexistent-uuid")

    assert_response :not_found
    assert_equal "User not found", response.body
  end

  test "should handle empty episode list" do
    @episode.destroy

    get user_calendar_path(@user.uuid)

    assert_response :success
    calendar_content = response.body
    assert_includes calendar_content, "BEGIN:VCALENDAR"
    assert_includes calendar_content, "END:VCALENDAR"
    # Should not include any VEVENT blocks
    assert_not_includes calendar_content, "BEGIN:VEVENT"
  end
end
