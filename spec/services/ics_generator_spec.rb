require "rails_helper"

RSpec.describe IcsGenerator do
  let(:user) { create(:user) }
  let(:series) { create(:series) }
  let!(:episode) { create(:episode, :upcoming, series: series, title: "Test Episode", episode_number: 5) }
  let(:generator) { described_class.new(user) }

  before do
    user.user_series.create!(series: series)
  end

  describe "#generate" do
    context "basic ICS structure" do
      let(:ics_content) { generator.generate }

      it "generates valid ICS calendar" do
        expect(ics_content).to include("BEGIN:VCALENDAR")
        expect(ics_content).to include("END:VCALENDAR")
        expect(ics_content).to include("VERSION:2.0")
        expect(ics_content).to include("PRODID:-//TVDB Calendar//NONSGML v1.0//EN")
      end

      it "includes calendar metadata" do
        expect(ics_content).to include("X-WR-CALNAME:TV Shows")
        expect(ics_content).to include("X-WR-CALDESC:All episodes for your favorite TV shows from TheTVDB")
      end

      it "includes timezone definition" do
        expect(ics_content).to include("BEGIN:VTIMEZONE")
        expect(ics_content).to include("TZID:America/New_York")
        expect(ics_content).to include("END:VTIMEZONE")
      end
    end

    context "episode filtering" do
      let!(:past_episode) { create(:episode, :aired, series: series, title: "Past Episode", episode_number: 1) }
      let(:ics_content) { generator.generate }

      it "includes all episodes" do
        expect(ics_content).to include("Test Episode")
        expect(ics_content).to include("Past Episode")
      end
    end

    context "episode event formatting" do
      let(:ics_content) { generator.generate }

      it "formats episode events correctly" do
        expect(ics_content).to include("BEGIN:VEVENT")
        expect(ics_content).to include("END:VEVENT")
        expect(ics_content).to include("SUMMARY:Test Series")
        expect(ics_content).to include("LOCATION:Test Episode (01x05)")

        date_str = episode.air_date.strftime("%Y%m%d")
        date_end = (episode.air_date + 1.day).strftime("%Y%m%d")
        expect(ics_content).to include("DTSTART;VALUE=DATE:#{date_str}")
        expect(ics_content).to include("DTEND;VALUE=DATE:#{date_end}")
      end
    end

    context "IMDB integration" do
      context "when IMDB ID is available" do
        let(:ics_content) { generator.generate }

        it "includes IMDB URL" do
          expect(ics_content).to include("DESCRIPTION:Watch on IMDB: https://www.imdb.com/title/tt1234567/")
          expect(ics_content).to include("URL:https://www.imdb.com/title/tt1234567/")
        end
      end

      context "when IMDB ID is not available" do
        before { series.update!(imdb_id: nil) }
        let(:ics_content) { generator.generate }

        it "handles series without IMDB ID" do
          expect(ics_content).not_to include("DESCRIPTION:")
          expect(ics_content).not_to include("URL:")
        end
      end
    end

    context "season finale handling" do
      before { episode.update!(is_season_finale: true) }
      let(:ics_content) { generator.generate }

      it "handles season finale episodes" do
        expect(ics_content).to include("SUMMARY:Test Series - Season Finale")
      end
    end

    context "special character escaping" do
      before { episode.update!(title: "Episode, with; special \"characters\"") }
      let(:ics_content) { generator.generate }

      it "escapes special characters" do
        expect(ics_content).to include("Episode\\, with\\; special \\\"characters\\\"")
      end
    end

    context "empty episode list" do
      before { episode.destroy }
      let(:ics_content) { generator.generate }

      it "handles empty episode list" do
        expect(ics_content).to include("BEGIN:VCALENDAR")
        expect(ics_content).to include("END:VCALENDAR")
        expect(ics_content).not_to include("BEGIN:VEVENT")
      end
    end

    context "unique episode UIDs" do
      let!(:second_episode) { create(:episode, :upcoming, series: series, title: "Another Episode", episode_number: 6, air_date: Date.current + 2.days) }
      let(:ics_content) { generator.generate }

      it "generates unique UIDs for episodes" do
        uid_matches = ics_content.scan(/UID:episode-\d+-\d+@tvdbcalendar\.com/)
        expect(uid_matches.length).to eq(2)
        expect(uid_matches.uniq.length).to eq(uid_matches.length)
      end
    end

    context "timed episodes" do
      context "when air_datetime_utc is present" do
        before do
          air_time_utc = Time.parse("2025-07-21 20:00:00 UTC")
          episode.update!(
            air_datetime_utc: air_time_utc,
            runtime_minutes: 60
          )
        end

        let(:ics_content) { generator.generate }

        it "generates timed events" do
          expect(ics_content).to include("DTSTART;TZID=America/New_York:20250721T160000")
          expect(ics_content).to include("DTEND;TZID=America/New_York:20250721T170000")
          expect(ics_content).not_to include("VALUE=DATE")
        end
      end

      context "when air_datetime_utc is nil" do
        before { episode.update!(air_datetime_utc: nil) }
        let(:ics_content) { generator.generate }

        it "falls back to all-day event" do
          date_str = episode.air_date.strftime("%Y%m%d")
          date_end = (episode.air_date + 1.day).strftime("%Y%m%d")
          expect(ics_content).to include("DTSTART;VALUE=DATE:#{date_str}")
          expect(ics_content).to include("DTEND;VALUE=DATE:#{date_end}")
          expect(ics_content).not_to include("TZID=America/New_York")
        end
      end

      context "when runtime_minutes is nil" do
        before do
          air_time_utc = Time.parse("2025-07-21 20:00:00 UTC")
          episode.update!(
            air_datetime_utc: air_time_utc,
            runtime_minutes: nil
          )
        end

        let(:ics_content) { generator.generate }

        it "uses default duration" do
          expect(ics_content).to include("DTSTART;TZID=America/New_York:20250721T160000")
          expect(ics_content).to include("DTEND;TZID=America/New_York:20250721T163000")
        end
      end
    end

    context "timezone handling" do
      context "winter timezone (EST)" do
        before do
          future_winter_date = Date.parse("2026-01-15")
          air_time_utc = Time.parse("2026-01-15 21:00:00 UTC")
          episode.update!(
            air_datetime_utc: air_time_utc,
            runtime_minutes: 30,
            air_date: future_winter_date
          )
        end

        let(:ics_content) { generator.generate }

        it "handles winter timezone correctly" do
          # 9 PM UTC in winter = 4 PM EST
          expect(ics_content).to include("DTSTART;TZID=America/New_York:20260115T160000")
          expect(ics_content).to include("DTEND;TZID=America/New_York:20260115T163000")
        end
      end

      context "mixed episodes with and without air times" do
        let!(:timed_episode) do
          create(:episode, series: series, title: "Timed Episode", episode_number: 10,
                 air_date: Date.current + 2.days, air_datetime_utc: Time.parse("2025-07-21 20:00:00 UTC"),
                 runtime_minutes: 45)
        end
        let!(:allday_episode) do
          create(:episode, series: series, title: "All Day Episode", episode_number: 11,
                 air_date: Date.current + 3.days, air_datetime_utc: nil)
        end

        let(:ics_content) { generator.generate }

        it "handles mixed episodes with and without air times" do
          expect(ics_content).to include("DTSTART;TZID=America/New_York:")
          expect(ics_content).to include("DTSTART;VALUE=DATE:")
        end
      end

      context "timezone escaping" do
        before do
          air_time_utc = Time.parse("2025-07-21 20:00:00 UTC")
          episode.update!(air_datetime_utc: air_time_utc)
        end

        let(:ics_content) { generator.generate }

        it "properly escapes timezone info" do
          expect(ics_content).to include("TZID:America/New_York")
          expect(ics_content).not_to include("TZID:America\\/New_York")
        end
      end
    end
  end
end
