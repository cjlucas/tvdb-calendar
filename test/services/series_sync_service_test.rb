require "test_helper"

class SeriesSyncServiceTest < ActiveSupport::TestCase
  def setup
    @series = Series.create!(
      tvdb_id: rand(100000..999999),
      name: "Test Series"
    )
    @mock_client = Object.new
    @service = SeriesSyncService.new(@mock_client)
  end

  test "should sync episodes for series" do
    series_details = {
      "name" => "Test Series",
      "originalNetwork" => "HBO"
    }

    episodes_data = [
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

    @mock_client.define_singleton_method(:get_series_episodes) { |tvdb_id| episodes_data }

    @service.sync_episodes_for_series(@series, series_details)

    assert_equal 2, @series.episodes.count

    episode1 = @series.episodes.find_by(season_number: 1, episode_number: 1)
    assert_equal "Test Episode 1", episode1.title
    assert_equal Date.parse("2023-01-01"), episode1.air_date
    assert_not episode1.is_season_finale

    episode2 = @series.episodes.find_by(season_number: 1, episode_number: 2)
    assert_equal "Test Episode 2", episode2.title
    assert_equal Date.parse("2023-01-08"), episode2.air_date
    assert episode2.is_season_finale
  end

  test "should handle timezone detection from network" do
    # Test that network timezone mappings are correctly defined
    assert SeriesSyncService::NETWORK_TIMEZONE_MAPPINGS.present?
    assert_equal "America/New_York", SeriesSyncService::NETWORK_TIMEZONE_MAPPINGS[%w[HBO SHOWTIME STARZ EPIX]]
  end

  test "should extract default air times based on network" do
    # Test that HBO series get 8 PM default
    series_details_hbo = { "originalNetwork" => "HBO" }
    service = SeriesSyncService.new(@mock_client)
    default_time = service.send(:extract_default_air_time, series_details_hbo)
    assert_equal "20:00", default_time

    # Test that CBS series get 9 PM default
    series_details_cbs = { "originalNetwork" => "CBS" }
    default_time = service.send(:extract_default_air_time, series_details_cbs)
    assert_equal "21:00", default_time

    # Test that unknown networks get general default
    series_details_unknown = { "originalNetwork" => "UNKNOWN" }
    default_time = service.send(:extract_default_air_time, series_details_unknown)
    assert_equal "20:00", default_time
  end

  test "should skip episodes with missing required data" do
    series_details = { "name" => "Test Series" }

    episodes_data = [
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

    @mock_client.define_singleton_method(:get_series_episodes) { |tvdb_id| episodes_data }

    @service.sync_episodes_for_series(@series, series_details)

    # Only the valid episode should be synced
    assert_equal 1, @series.episodes.count
    episode = @series.episodes.first
    assert_equal "Valid Episode", episode.title
  end
end
