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
            "id" => 1001,
            "name" => "Test Episode 1",
            "aired" => "2023-01-01",
            "seasonNumber" => 1,
            "number" => 1,
            "finaleType" => "regular"
          },
          {
            "id" => 1002,
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
        allow(mock_client).to receive(:get_episode_details).and_return({ "overview" => nil })
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
            "id" => 2001,
            "name" => "Valid Episode",
            "aired" => "2023-01-01",
            "seasonNumber" => 1,
            "number" => 1
          },
          {
            "id" => 2002,
            "name" => "Missing Air Date",
            "seasonNumber" => 1,
            "number" => 2
            # missing "aired"
          },
          {
            "id" => 2003,
            "name" => "Missing Season Number",
            "aired" => "2023-01-01",
            "number" => 3
            # missing "seasonNumber"
          }
        ]
      end

      before do
        allow(mock_client).to receive(:get_series_episodes).with(series.tvdb_id).and_return(episodes_data)
        allow(mock_client).to receive(:get_episode_details).and_return({ "overview" => nil })
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

  describe "episode overview functionality" do
    let(:series_details) { { "name" => "Test Series", "originalNetwork" => "HBO" } }

    describe "#fetch_episode_overview" do
      context "when episode ID is present" do
        it "fetches overview from client" do
          allow(mock_client).to receive(:get_episode_details).with(123).and_return({
            "overview" => "This is a detailed episode overview with plot information."
          })

          result = service.send(:fetch_episode_overview, 123)

          expect(result).to eq("This is a detailed episode overview with plot information.")
          expect(mock_client).to have_received(:get_episode_details).with(123)
        end

        it "returns nil when overview is missing" do
          allow(mock_client).to receive(:get_episode_details).with(123).and_return({
            "name" => "Test Episode"
          })

          result = service.send(:fetch_episode_overview, 123)

          expect(result).to be_nil
        end

        it "returns nil when overview is nil" do
          allow(mock_client).to receive(:get_episode_details).with(123).and_return({
            "overview" => nil
          })

          result = service.send(:fetch_episode_overview, 123)

          expect(result).to be_nil
        end

        it "returns empty string when overview is empty" do
          allow(mock_client).to receive(:get_episode_details).with(123).and_return({
            "overview" => ""
          })

          result = service.send(:fetch_episode_overview, 123)

          expect(result).to eq("")
        end
      end

      context "when episode ID is nil" do
        before do
          allow(mock_client).to receive(:get_episode_details)
        end

        it "returns nil without API call" do
          result = service.send(:fetch_episode_overview, nil)

          expect(result).to be_nil
          expect(mock_client).not_to have_received(:get_episode_details)
        end
      end

      context "when episode ID is empty" do
        before do
          allow(mock_client).to receive(:get_episode_details)
        end

        it "returns nil without API call" do
          result = service.send(:fetch_episode_overview, "")

          expect(result).to be_nil
          expect(mock_client).not_to have_received(:get_episode_details)
        end
      end

      context "when API call fails" do
        before do
          allow(mock_client).to receive(:get_episode_details).with(123).and_raise(StandardError, "API Error")
          allow(Rails.logger).to receive(:warn)
        end

        it "handles errors gracefully and returns nil" do
          result = service.send(:fetch_episode_overview, 123)

          expect(result).to be_nil
          expect(Rails.logger).to have_received(:warn).with(
            "SeriesSyncService: Failed to fetch episode overview for episode 123: API Error"
          )
        end

        it "logs warning with episode ID" do
          service.send(:fetch_episode_overview, 123)

          expect(Rails.logger).to have_received(:warn).with(
            "SeriesSyncService: Failed to fetch episode overview for episode 123: API Error"
          )
        end
      end
    end

    describe "overview integration during episode sync" do
      let(:episodes_data) do
        [
          {
            "id" => 1001,
            "name" => "Episode with Overview",
            "aired" => "2023-01-01",
            "seasonNumber" => 1,
            "number" => 1,
            "finaleType" => "regular"
          },
          {
            "id" => 1002,
            "name" => "Episode without Overview",
            "aired" => "2023-01-08",
            "seasonNumber" => 1,
            "number" => 2,
            "finaleType" => "season"
          }
        ]
      end

      before do
        allow(mock_client).to receive(:get_series_episodes).with(series.tvdb_id).and_return(episodes_data)

        # Mock different overview responses for different episodes
        allow(mock_client).to receive(:get_episode_details).with(1001).and_return({
          "overview" => "This episode follows the main characters as they discover something important."
        })
        allow(mock_client).to receive(:get_episode_details).with(1002).and_return({
          "overview" => nil
        })
      end

      it "stores episode overviews correctly" do
        service.sync_episodes_for_series(series, series_details)

        episode1 = series.episodes.find_by(season_number: 1, episode_number: 1)
        expect(episode1.overview).to eq("This episode follows the main characters as they discover something important.")

        episode2 = series.episodes.find_by(season_number: 1, episode_number: 2)
        expect(episode2.overview).to be_nil
      end

      it "calls get_episode_details for each episode" do
        service.sync_episodes_for_series(series, series_details)

        expect(mock_client).to have_received(:get_episode_details).with(1001)
        expect(mock_client).to have_received(:get_episode_details).with(1002)
      end
    end

    describe "overview with special characters" do
      let(:episodes_data) do
        [
          {
            "id" => 1003,
            "name" => "Special Episode",
            "aired" => "2023-01-01",
            "seasonNumber" => 1,
            "number" => 1
          }
        ]
      end

      before do
        allow(mock_client).to receive(:get_series_episodes).with(series.tvdb_id).and_return(episodes_data)
        allow(mock_client).to receive(:get_episode_details).with(1003).and_return({
          "overview" => "Episode with \"quotes\", commas, semicolons; and\nnewlines."
        })
      end

      it "preserves special characters in overview" do
        service.sync_episodes_for_series(series, series_details)

        episode = series.episodes.find_by(season_number: 1, episode_number: 1)
        expect(episode.overview).to eq("Episode with \"quotes\", commas, semicolons; and\nnewlines.")
      end
    end

    describe "overview persistence with episode updates" do
      let!(:existing_episode) do
        series.episodes.create!(
          season_number: 1,
          episode_number: 1,
          title: "Old Title",
          air_date: Date.parse("2023-01-01"),
          overview: "Old overview content"
        )
      end

      let(:episodes_data) do
        [
          {
            "id" => 1004,
            "name" => "Updated Title",
            "aired" => "2023-01-01",
            "seasonNumber" => 1,
            "number" => 1
          }
        ]
      end

      before do
        allow(mock_client).to receive(:get_series_episodes).with(series.tvdb_id).and_return(episodes_data)
        allow(mock_client).to receive(:get_episode_details).with(1004).and_return({
          "overview" => "New updated overview content"
        })
      end

      it "updates existing episode overview" do
        service.sync_episodes_for_series(series, series_details)

        existing_episode.reload
        expect(existing_episode.title).to eq("Updated Title")
        expect(existing_episode.overview).to eq("New updated overview content")
      end
    end

    describe "overview with long text content" do
      let(:episodes_data) do
        [
          {
            "id" => 1005,
            "name" => "Long Overview Episode",
            "aired" => "2023-01-01",
            "seasonNumber" => 1,
            "number" => 1
          }
        ]
      end

      let(:long_overview) do
        "This is a very long episode overview that contains multiple sentences and detailed plot information. " \
        "It describes the characters, their motivations, and the events that unfold during the episode. " \
        "The overview might include information about character development, plot twists, and important story elements. " \
        "It could also mention guest stars, locations, and other relevant details that viewers might find interesting."
      end

      before do
        allow(mock_client).to receive(:get_series_episodes).with(series.tvdb_id).and_return(episodes_data)
        allow(mock_client).to receive(:get_episode_details).with(1005).and_return({
          "overview" => long_overview
        })
      end

      it "handles long overview text correctly" do
        service.sync_episodes_for_series(series, series_details)

        episode = series.episodes.find_by(season_number: 1, episode_number: 1)
        expect(episode.overview).to eq(long_overview)
        expect(episode.overview.length).to be > 200
      end
    end
  end
end
