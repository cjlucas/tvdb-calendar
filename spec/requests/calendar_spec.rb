require "rails_helper"

RSpec.describe "Calendar API", type: :request do
  let(:user) { create(:user) }
  let(:series) { create(:series) }
  let!(:episode) { create(:episode, :upcoming, series: series, title: "Test Episode", episode_number: 1) }

  before do
    user.user_series.create!(series: series)
  end

  describe "GET /calendar/:uuid" do
    context "with valid user UUID" do
      before do
        get user_calendar_path(user.uuid)
      end

      it "generates ICS calendar successfully" do
        expect(response).to have_http_status(:success)
        expect(response.content_type).to eq("text/calendar; charset=utf-8")

        calendar_content = response.body
        expect(calendar_content).to include("BEGIN:VCALENDAR")
        expect(calendar_content).to include("END:VCALENDAR")
        expect(calendar_content).to include("Test Series")
        expect(calendar_content).to include("Test Episode (01x01)")
      end
    end

    context "with proper ICS headers" do
      before do
        get user_calendar_path(user.uuid), headers: { "Accept" => "text/calendar" }
      end

      it "serves ICS with proper filename" do
        expect(response).to have_http_status(:success)
        expect(response.headers["Content-Disposition"]).to include("tvdb-calendar-#{user.uuid}.ics")
      end
    end

    context "with non-existent user" do
      before do
        get user_calendar_path("nonexistent-uuid")
      end

      it "returns 404 for non-existent user" do
        expect(response).to have_http_status(:not_found)
        expect(response.body).to eq("User not found")
      end
    end

    context "with empty episode list" do
      before do
        episode.destroy
        get user_calendar_path(user.uuid)
      end

      it "handles empty episode list" do
        expect(response).to have_http_status(:success)

        calendar_content = response.body
        expect(calendar_content).to include("BEGIN:VCALENDAR")
        expect(calendar_content).to include("END:VCALENDAR")
        # Should not include any VEVENT blocks
        expect(calendar_content).not_to include("BEGIN:VEVENT")
      end
    end
  end
end
