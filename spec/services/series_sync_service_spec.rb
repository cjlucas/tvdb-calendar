require "rails_helper"

RSpec.describe SeriesSyncService do
  let(:series) { create(:series) }
  let(:mock_client) { instance_double(TvdbClient) }
  let(:service) { described_class.new(mock_client) }

  describe "#sync_episodes_for_series" do
    let(:series_details) do
      {
        "name" => "Test Series",
        "originalNetwork" => "HBO"
      }
    end

    context "with valid episodes data" do
      let(:episodes_data) do
        [
          {
            "name" => "Test Episode 1",
            "aired" => "2023-01-01",
            "seasonNumber" => 1,
            "number" => 1,
            "finaleType" => "regular"
          },
          {
            "name" => "Test Episode 2",
            "aired" => "2023-01-08",
            "seasonNumber" => 1,
            "number" => 2,
            "finaleType" => "season"
          }
        ]
      end

      before do
        allow(mock_client).to receive(:get_series_episodes).with(series.tvdb_id).and_return(episodes_data)
      end

      it "syncs episodes correctly" do
        service.sync_episodes_for_series(series, series_details)

        expect(series.episodes.count).to eq(2)

        episode1 = series.episodes.find_by(season_number: 1, episode_number: 1)
        expect(episode1.title).to eq("Test Episode 1")
        expect(episode1.air_date).to eq(Date.parse("2023-01-01"))
        expect(episode1.is_season_finale).to be false

        episode2 = series.episodes.find_by(season_number: 1, episode_number: 2)
        expect(episode2.title).to eq("Test Episode 2")
        expect(episode2.air_date).to eq(Date.parse("2023-01-08"))
        expect(episode2.is_season_finale).to be true
      end
    end

    context "with episodes missing required data" do
      let(:episodes_data) do
        [
          {
            "name" => "Valid Episode",
            "aired" => "2023-01-01",
            "seasonNumber" => 1,
            "number" => 1
          },
          {
            "name" => "Missing Air Date",
            "seasonNumber" => 1,
            "number" => 2
            # missing "aired"
          },
          {
            "name" => "Missing Season Number",
            "aired" => "2023-01-01",
            "number" => 3
            # missing "seasonNumber"
          }
        ]
      end

      before do
        allow(mock_client).to receive(:get_series_episodes).with(series.tvdb_id).and_return(episodes_data)
      end

      it "skips episodes with missing required data" do
        service.sync_episodes_for_series(series, series_details)

        # Only the valid episode should be synced
        expect(series.episodes.count).to eq(1)
        episode = series.episodes.first
        expect(episode.title).to eq("Valid Episode")
      end
    end
  end

  describe "network timezone mappings" do
    it "has network timezone mappings defined" do
      expect(described_class::NETWORK_TIMEZONE_MAPPINGS).to be_present
      expect(described_class::NETWORK_TIMEZONE_MAPPINGS[%w[HBO SHOWTIME STARZ EPIX]]).to eq("America/New_York")
    end
  end

  describe "#extract_default_air_time" do
    context "with HBO network" do
      let(:series_details_hbo) { { "originalNetwork" => "HBO" } }

      it "returns 8 PM default time" do
        default_time = service.send(:extract_default_air_time, series_details_hbo)
        expect(default_time).to eq("20:00")
      end
    end

    context "with CBS network" do
      let(:series_details_cbs) { { "originalNetwork" => "CBS" } }

      it "returns 9 PM default time" do
        default_time = service.send(:extract_default_air_time, series_details_cbs)
        expect(default_time).to eq("21:00")
      end
    end

    context "with unknown network" do
      let(:series_details_unknown) { { "originalNetwork" => "UNKNOWN" } }

      it "returns general default time" do
        default_time = service.send(:extract_default_air_time, series_details_unknown)
        expect(default_time).to eq("20:00")
      end
    end
  end

  describe "#sync_series_data" do
    context "with complete series data" do
      let(:series_details) do
        {
          "name" => "Updated Series Name",
          "remoteIds" => [
            { "sourceName" => "IMDB", "id" => "tt1234567" },
            { "sourceName" => "TheMovieDB", "id" => "987654" }
          ],
          "originalNetwork" => "HBO"
        }
      end

      let(:episodes_data) do
        [
          {
            "name" => "Pilot",
            "aired" => "2023-01-01",
            "seasonNumber" => 1,
            "number" => 1,
            "finaleType" => "regular"
          }
        ]
      end

      before do
        allow(mock_client).to receive(:get_series_details).with(series.tvdb_id).and_return(series_details)
        allow(mock_client).to receive(:get_series_episodes).with(series.tvdb_id).and_return(episodes_data)
      end

      it "syncs series data and episodes" do
        service.sync_series_data(series)

        # Verify series data was updated
        series.reload
        expect(series.name).to eq("Updated Series Name")
        expect(series.imdb_id).to eq("tt1234567")

        # Verify episodes were synced
        expect(series.episodes.count).to eq(1)
        episode = series.episodes.first
        expect(episode.title).to eq("Pilot")
        expect(episode.air_date).to eq(Date.parse("2023-01-01"))
        expect(episode.season_number).to eq(1)
        expect(episode.episode_number).to eq(1)
      end
    end

    context "with series without IMDB ID" do
      let(:series_details) do
        {
          "name" => "Series Without IMDB",
          "remoteIds" => [
            { "sourceName" => "TheMovieDB", "id" => "987654" }
          ]
        }
      end

      let(:episodes_data) { [] }

      before do
        allow(mock_client).to receive(:get_series_details).with(series.tvdb_id).and_return(series_details)
        allow(mock_client).to receive(:get_series_episodes).with(series.tvdb_id).and_return(episodes_data)
      end

      it "handles series with no IMDB ID" do
        service.sync_series_data(series)

        series.reload
        expect(series.name).to eq("Series Without IMDB")
        expect(series.imdb_id).to be_nil
      end
    end

    context "with series without remote IDs" do
      let(:series_details) do
        {
          "name" => "Series Without Remote IDs"
        }
      end

      let(:episodes_data) { [] }

      before do
        allow(mock_client).to receive(:get_series_details).with(series.tvdb_id).and_return(series_details)
        allow(mock_client).to receive(:get_series_episodes).with(series.tvdb_id).and_return(episodes_data)
      end

      it "handles series with no remoteIds" do
        service.sync_series_data(series)

        series.reload
        expect(series.name).to eq("Series Without Remote IDs")
        expect(series.imdb_id).to be_nil
      end
    end
  end
end
