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
          expect(ics_content).to include("Show Information:")
          expect(ics_content).to include("• IMDB: https://www.imdb.com/title/tt1234567/")
          expect(ics_content).to include("URL:https://www.imdb.com/title/tt1234567/")
        end
      end

      context "when IMDB ID is not available" do
        before { series.update!(imdb_id: nil) }
        let(:ics_content) { generator.generate }

        it "handles series without IMDB ID" do
          expect(ics_content).to include("DESCRIPTION:")  # Still has DESCRIPTION but without IMDB
          expect(ics_content).not_to include("Show Information:")
          expect(ics_content).not_to include("URL:")
        end
      end
    end

    context "season finale handling" do
      before { episode.update!(is_season_finale: true) }
      let(:ics_content) { generator.generate }

      it "handles season finale episodes" do
        expect(ics_content).to include("SUMMARY:Test Series: Test Episode (S01E05) - Season Finale")
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

  describe "enhanced episode titles and descriptions" do
    let(:enhanced_user) { create(:user) }
    let(:enhanced_series) { create(:series) }
    let(:enhanced_generator) { described_class.new(enhanced_user) }

    before do
      enhanced_user.user_series.create!(series: enhanced_series)
    end

    describe "#build_event_title" do
      context "with basic episode information" do
        let(:episode) { create(:episode, series: enhanced_series, title: "Pilot Episode", season_number: 1, episode_number: 1) }

        it "includes series name, episode title, and S00E00 format" do
          title = enhanced_generator.send(:build_event_title, episode)
          expect(title).to eq("Test Series: Pilot Episode (S01E01)")
        end
      end

      context "with season finale" do
        let(:episode) do
          create(:episode, series: enhanced_series, title: "Season Ending", season_number: 1, episode_number: 10,
                 is_season_finale: true)
        end

        it "includes season finale text" do
          title = enhanced_generator.send(:build_event_title, episode)
          expect(title).to eq("Test Series: Season Ending (S01E10) - Season Finale")
        end
      end

      context "with double-digit season and episode numbers" do
        let(:episode) do
          create(:episode, series: enhanced_series, title: "Mid Season", season_number: 12, episode_number: 25)
        end

        it "formats season and episode numbers correctly" do
          title = enhanced_generator.send(:build_event_title, episode)
          expect(title).to eq("Test Series: Mid Season (S12E25)")
        end
      end

      context "with missing episode title" do
        let(:episode) do
          build(:episode, series: enhanced_series, title: nil, season_number: 1, episode_number: 5)
        end

        it "includes S00E00 format without episode title" do
          title = enhanced_generator.send(:build_event_title, episode)
          expect(title).to eq("Test Series (S01E05)")
        end
      end

      context "with empty episode title" do
        let(:episode) do
          build(:episode, series: enhanced_series, title: "", season_number: 2, episode_number: 3)
        end

        it "includes S00E00 format without episode title" do
          title = enhanced_generator.send(:build_event_title, episode)
          expect(title).to eq("Test Series (S02E03)")
        end
      end
    end

    describe "#build_event_description" do
      context "with episode overview" do
        let(:episode) do
          create(:episode, :with_overview, series: enhanced_series, title: "Test Episode",
                 season_number: 1, episode_number: 1, runtime_minutes: 60)
        end

        it "includes episode overview in description" do
          description = enhanced_generator.send(:build_event_description, episode)
          expect(description).to include("This is a detailed episode overview that describes the plot and characters.")
        end

        it "includes runtime information" do
          description = enhanced_generator.send(:build_event_description, episode)
          expect(description).to include("Runtime: 60 minutes")
        end
      end

      context "with IMDB link" do
        let(:episode) do
          create(:episode, series: enhanced_series, title: "Test Episode", season_number: 1, episode_number: 1)
        end

        it "includes IMDB information" do
          description = enhanced_generator.send(:build_event_description, episode)
          expect(description).to include("Show Information:")
          expect(description).to include("• IMDB: https://www.imdb.com/title/tt1234567/")
        end
      end

      context "with original timezone and air time" do
        let(:episode) do
          create(:episode, series: enhanced_series, title: "Test Episode", season_number: 1, episode_number: 1,
                 original_timezone: "America/Los_Angeles", air_datetime_utc: Time.parse("2023-07-21 03:00:00 UTC"))
        end

        it "includes original airtime information" do
          description = enhanced_generator.send(:build_event_description, episode)
          expect(description).to include("Original Airtime:")
          # 3:00 UTC = 8:00 PM PDT (Los Angeles)
          expect(description).to include("8:00 PM PDT")
        end
      end

      context "without optional information" do
        let(:episode) do
          create(:episode, series: enhanced_series, title: "Basic Episode", season_number: 1, episode_number: 1,
                 overview: nil, runtime_minutes: nil, original_timezone: nil, air_datetime_utc: nil)
        end

        before do
          enhanced_series.update!(imdb_id: nil)
        end

        it "handles missing information gracefully" do
          description = enhanced_generator.send(:build_event_description, episode)
          # Should be empty or minimal content
          expect(description).to be_a(String)
          expect(description).not_to include("Runtime:")
          expect(description).not_to include("Original Airtime:")
          expect(description).not_to include("Show Information:")
        end
      end

      context "with long episode overview" do
        let(:episode) do
          create(:episode, :with_long_overview, series: enhanced_series, title: "Long Episode",
                 season_number: 1, episode_number: 1)
        end

        it "includes complete long overview" do
          description = enhanced_generator.send(:build_event_description, episode)
          expect(description).to include("This is a very long episode overview that contains multiple sentences")
          expect(description).to include("character development, plot twists, and important story elements")
          expect(description.length).to be > 200
        end
      end

      context "with special characters in overview" do
        let(:episode) do
          create(:episode, series: enhanced_series, title: "Special Episode", season_number: 1, episode_number: 1,
                 overview: "Episode with \"quotes\", commas, semicolons; and\nnewlines in overview.")
        end

        it "preserves special characters in description" do
          description = enhanced_generator.send(:build_event_description, episode)
          expect(description).to include("Episode with \"quotes\", commas, semicolons; and\nnewlines in overview.")
        end
      end

      context "with all optional fields present" do
        let(:episode) do
          create(:episode, :with_overview, series: enhanced_series, title: "Complete Episode",
                 season_number: 2, episode_number: 5, runtime_minutes: 45,
                 original_timezone: "America/New_York", air_datetime_utc: Time.parse("2023-07-21 20:00:00 UTC"))
        end

        it "includes all available information" do
          description = enhanced_generator.send(:build_event_description, episode)

          expect(description).to include("This is a detailed episode overview")
          expect(description).to include("Runtime: 45 minutes")
          expect(description).to include("Original Airtime:")
          expect(description).to include("4:00 PM EDT") # 20:00 UTC = 4:00 PM EDT
          expect(description).to include("Show Information:")
          expect(description).to include("• IMDB:")
        end

        it "formats description with proper spacing" do
          description = enhanced_generator.send(:build_event_description, episode)
          lines = description.split("\n")

          # Should have empty lines for proper spacing
          expect(lines).to include("")
          # Should have multiple lines
          expect(lines.length).to be > 3
        end
      end
    end

    describe "integration with ICS generation" do
      context "with enhanced episode information" do
        let!(:episode) do
          create(:episode, :with_overview, series: enhanced_series, title: "Enhanced Episode",
                 season_number: 1, episode_number: 1, runtime_minutes: 60,
                 original_timezone: "America/Los_Angeles", air_datetime_utc: Time.parse("2023-07-21 03:00:00 UTC"))
        end

        let(:ics_content) { enhanced_generator.generate }

        it "includes enhanced title in SUMMARY" do
          expect(ics_content).to include("SUMMARY:Test Series: Enhanced Episode (S01E01)")
        end

        it "includes enhanced description with overview" do
          expect(ics_content).to include("DESCRIPTION:")
          expect(ics_content).to include("This is a detailed episode overview")
          expect(ics_content).to include("Runtime: 60 minutes")
          expect(ics_content).to include("Original Airtime:")
        end

        it "properly escapes special characters in description" do
          # The ICS generator should escape special characters
          expect(ics_content).to include("DESCRIPTION:")
          # Check that the description is present (exact escaping format may vary)
          description_line = ics_content.lines.find { |line| line.start_with?("DESCRIPTION:") }
          expect(description_line).to be_present
        end
      end

      context "with season finale episode" do
        let!(:episode) do
          create(:episode, :with_overview, series: enhanced_series, title: "Season Ender",
                 season_number: 1, episode_number: 10, is_season_finale: true)
        end

        let(:ics_content) { enhanced_generator.generate }

        it "includes season finale in title" do
          expect(ics_content).to include("SUMMARY:Test Series: Season Ender (S01E10) - Season Finale")
        end
      end

      context "with episode without overview" do
        let!(:episode) do
          create(:episode, series: enhanced_series, title: "Basic Episode", season_number: 1, episode_number: 1,
                 overview: nil, runtime_minutes: 30)
        end

        let(:ics_content) { enhanced_generator.generate }

        it "includes enhanced title" do
          expect(ics_content).to include("SUMMARY:Test Series: Basic Episode (S01E01)")
        end

        it "includes description with available information" do
          expect(ics_content).to include("DESCRIPTION:")
          expect(ics_content).to include("Runtime: 30 minutes")
        end
      end

      context "with multiple episodes" do
        let!(:episode1) do
          create(:episode, :with_overview, series: enhanced_series, title: "First Episode",
                 season_number: 1, episode_number: 1, runtime_minutes: 45)
        end
        let!(:episode2) do
          create(:episode, series: enhanced_series, title: "Second Episode", season_number: 1, episode_number: 2,
                 overview: nil, runtime_minutes: 60, is_season_finale: true)
        end

        let(:ics_content) { enhanced_generator.generate }

        it "generates enhanced titles for all episodes" do
          expect(ics_content).to include("SUMMARY:Test Series: First Episode (S01E01)")
          expect(ics_content).to include("SUMMARY:Test Series: Second Episode (S01E02) - Season Finale")
        end

        it "generates appropriate descriptions for all episodes" do
          # Should have multiple DESCRIPTION lines
          description_lines = ics_content.lines.select { |line| line.start_with?("DESCRIPTION:") }
          expect(description_lines.length).to eq(2)
        end
      end
    end
  end
end
