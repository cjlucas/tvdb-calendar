require "rails_helper"

RSpec.describe Episode, type: :model do
  let(:user) { create(:user) }
  let(:series) { create(:series) }
  let(:episode) { build(:episode, series: series, title: "Test Episode", episode_number: 5) }

  before do
    user.user_series.create!(series: series)
  end

  describe "validations" do
    it "is valid with valid attributes" do
      expect(episode).to be_valid
    end

    it "requires title" do
      episode.title = nil
      expect(episode).not_to be_valid
      expect(episode.errors[:title]).to include("can't be blank")
    end

    it "requires season_number" do
      episode.season_number = nil
      expect(episode).not_to be_valid
      expect(episode.errors[:season_number]).to include("can't be blank")
    end

    it "requires non-negative season_number" do
      episode.season_number = -1
      expect(episode).not_to be_valid
      expect(episode.errors[:season_number]).to include("must be greater than or equal to 0")
    end

    it "requires episode_number" do
      episode.episode_number = nil
      expect(episode).not_to be_valid
      expect(episode.errors[:episode_number]).to include("can't be blank")
    end

    it "requires positive episode_number" do
      episode.episode_number = 0
      expect(episode).not_to be_valid
      expect(episode.errors[:episode_number]).to include("must be greater than 0")
    end

    it "requires air_date" do
      episode.air_date = nil
      expect(episode).not_to be_valid
      expect(episode.errors[:air_date]).to include("can't be blank")
    end

    describe "runtime_minutes validation" do
      it "allows nil runtime_minutes" do
        episode.runtime_minutes = nil
        expect(episode).to be_valid
      end

      it "allows positive runtime_minutes" do
        episode.runtime_minutes = 30
        expect(episode).to be_valid
      end

      it "does not allow negative runtime_minutes" do
        episode.runtime_minutes = -5
        expect(episode).not_to be_valid
        expect(episode.errors[:runtime_minutes]).to include("must be greater than 0")
      end
    end
  end

  describe "associations" do
    it { is_expected.to belong_to(:series) }

    it "belongs to series" do
      expect(episode.series).to eq(series)
    end

    it "has users through series" do
      expect(episode).to respond_to(:users)
      expect(episode.users).to include(user)
    end
  end

  describe "#episode_code" do
    it "formats correctly with single digits" do
      episode.season_number = 1
      episode.episode_number = 5
      expect(episode.episode_code).to eq("01x05")
    end

    it "formats correctly with double digits" do
      episode.season_number = 12
      episode.episode_number = 25
      expect(episode.episode_code).to eq("12x25")
    end
  end

  describe "#full_title" do
    it "returns series name" do
      expected = "Test Series"
      expect(episode.full_title).to eq(expected)
    end

    it "includes season finale text" do
      episode.is_season_finale = true
      expected = "Test Series - Season Finale"
      expect(episode.full_title).to eq(expected)
    end
  end

  describe "#location_text" do
    it "formats correctly" do
      expected = "Test Episode (01x05)"
      expect(episode.location_text).to eq(expected)
    end
  end

  describe "scopes" do
    let!(:future_episode) { create(:episode, :upcoming, series: series, title: "Future Episode", episode_number: 1) }
    let!(:past_episode) { create(:episode, :aired, series: series, title: "Past Episode", episode_number: 2) }

    describe ".upcoming" do
      it "returns future episodes" do
        upcoming_episodes = Episode.upcoming
        expect(upcoming_episodes).to include(future_episode)
        expect(upcoming_episodes).not_to include(past_episode)
      end
    end

    describe ".aired" do
      it "returns past episodes" do
        aired_episodes = Episode.aired
        expect(aired_episodes).to include(past_episode)
        expect(aired_episodes).not_to include(future_episode)
      end
    end

    describe ".upcoming_with_time" do
      let!(:future_episode_with_time) do
        create(:episode, series: series, title: "Future Episode", episode_number: 10,
               air_date: Date.current + 1.day, air_datetime_utc: 1.hour.from_now.utc)
      end
      let!(:past_episode_with_time) do
        create(:episode, series: series, title: "Past Episode", episode_number: 11,
               air_date: Date.current - 1.day, air_datetime_utc: 1.hour.ago.utc)
      end

      it "filters by air_datetime_utc" do
        upcoming_episodes = Episode.upcoming_with_time
        expect(upcoming_episodes).to include(future_episode_with_time)
        expect(upcoming_episodes).not_to include(past_episode_with_time)
      end
    end

    describe ".aired_with_time" do
      let!(:future_episode_with_time) do
        create(:episode, series: series, title: "Future Episode", episode_number: 12,
               air_date: Date.current + 1.day, air_datetime_utc: 1.hour.from_now.utc)
      end
      let!(:past_episode_with_time) do
        create(:episode, series: series, title: "Past Episode", episode_number: 13,
               air_date: Date.current - 1.day, air_datetime_utc: 1.hour.ago.utc)
      end

      it "filters by air_datetime_utc" do
        aired_episodes = Episode.aired_with_time
        expect(aired_episodes).to include(past_episode_with_time)
        expect(aired_episodes).not_to include(future_episode_with_time)
      end
    end
  end

  describe "#has_specific_air_time?" do
    context "when air_datetime_utc is nil" do
      it "returns false" do
        episode.air_datetime_utc = nil
        expect(episode.has_specific_air_time?).to be false
      end
    end

    context "when air_datetime_utc is present" do
      it "returns true" do
        episode.air_datetime_utc = Time.current.utc
        expect(episode.has_specific_air_time?).to be true
      end
    end
  end

  describe "#air_time_in_timezone" do
    context "when air_datetime_utc is nil" do
      it "returns nil" do
        episode.air_datetime_utc = nil
        expect(episode.air_time_in_timezone).to be_nil
      end
    end

    context "when air_datetime_utc is present" do
      it "converts to target timezone" do
        utc_time = Time.parse("2025-07-21 20:00:00 UTC")
        episode.air_datetime_utc = utc_time

        ny_time = episode.air_time_in_timezone("America/New_York")
        expect(ny_time.strftime("%H:%M")).to eq("16:00") # 8 PM UTC = 4 PM EDT
      end
    end
  end

  describe "#end_time_in_timezone" do
    context "when air_datetime_utc is nil" do
      it "returns nil" do
        episode.air_datetime_utc = nil
        episode.runtime_minutes = 30
        expect(episode.end_time_in_timezone).to be_nil
      end
    end

    context "when runtime_minutes is nil" do
      it "returns nil" do
        episode.air_datetime_utc = Time.current.utc
        episode.runtime_minutes = nil
        expect(episode.end_time_in_timezone).to be_nil
      end
    end

    context "when both air_datetime_utc and runtime_minutes are present" do
      it "calculates end time correctly" do
        utc_time = Time.parse("2025-07-21 20:00:00 UTC")
        episode.air_datetime_utc = utc_time
        episode.runtime_minutes = 60

        end_time = episode.end_time_in_timezone("America/New_York")
        expect(end_time.strftime("%H:%M")).to eq("17:00") # 4 PM + 1 hour = 5 PM
      end

      it "does not round when runtime ends on exact quarter hour" do
        utc_time = Time.parse("2025-07-21 20:00:00 UTC") # 4 PM EDT
        episode.air_datetime_utc = utc_time
        episode.runtime_minutes = 60 # Ends at 5:00 PM EDT

        end_time = episode.end_time_in_timezone("America/New_York")
        expect(end_time.strftime("%H:%M")).to eq("17:00") # Should stay at 5:00 PM
      end

      it "rounds up to nearest 15 minutes when runtime ends between quarter hours" do
        utc_time = Time.parse("2025-07-21 20:00:00 UTC") # 4 PM EDT
        episode.air_datetime_utc = utc_time
        episode.runtime_minutes = 22 # Ends at 4:22 PM EDT

        end_time = episode.end_time_in_timezone("America/New_York")
        expect(end_time.strftime("%H:%M")).to eq("16:30") # Should round up to 4:30 PM
      end

      it "rounds up to nearest 15 minutes at 1 minute past quarter hour" do
        utc_time = Time.parse("2025-07-21 20:00:00 UTC") # 4 PM EDT
        episode.air_datetime_utc = utc_time
        episode.runtime_minutes = 46 # Ends at 4:46 PM EDT

        end_time = episode.end_time_in_timezone("America/New_York")
        expect(end_time.strftime("%H:%M")).to eq("17:00") # Should round up to 5:00 PM
      end

      it "rounds up to nearest 15 minutes at 14 minutes past quarter hour" do
        utc_time = Time.parse("2025-07-21 20:00:00 UTC") # 4 PM EDT
        episode.air_datetime_utc = utc_time
        episode.runtime_minutes = 59 # Ends at 4:59 PM EDT

        end_time = episode.end_time_in_timezone("America/New_York")
        expect(end_time.strftime("%H:%M")).to eq("17:00") # Should round up to 5:00 PM
      end

      it "handles rounding across hour boundaries" do
        utc_time = Time.parse("2025-07-21 20:47:00 UTC") # 4:47 PM EDT
        episode.air_datetime_utc = utc_time
        episode.runtime_minutes = 25 # Ends at 5:12 PM EDT

        end_time = episode.end_time_in_timezone("America/New_York")
        expect(end_time.strftime("%H:%M")).to eq("17:15") # Should round up to 5:15 PM
      end
    end
  end

  describe "#runtime_duration" do
    context "when runtime_minutes is nil" do
      it "returns nil" do
        episode.runtime_minutes = nil
        expect(episode.runtime_duration).to be_nil
      end
    end

    context "when runtime_minutes is present" do
      it "returns duration object" do
        episode.runtime_minutes = 45
        duration = episode.runtime_duration
        expect(duration).to eq(45.minutes)
      end
    end
  end
end
