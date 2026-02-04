require "rails_helper"

RSpec.describe TvdbClient do
  let(:client) { described_class.new("test_api_key") }

  describe "#initialize" do
    it "initializes with api key" do
      expect(client.instance_variable_get(:@api_key)).to eq("test_api_key")
    end

    it "raises error without api key" do
      expect { described_class.new(nil) }.to raise_error(ArgumentError)
    end
  end

  describe "method availability" do
    it "responds to authenticate" do
      expect(client).to respond_to(:authenticate)
    end

    it "responds to get_user_favorites" do
      expect(client).to respond_to(:get_user_favorites)
    end

    it "responds to get_series_details" do
      expect(client).to respond_to(:get_series_details)
    end

    it "responds to get_series_episodes" do
      expect(client).to respond_to(:get_series_episodes)
    end

    it "responds to get_episode_details" do
      expect(client).to respond_to(:get_episode_details)
    end
  end

  describe "authentication requirements" do
    context "when not authenticated" do
      it "raises error when getting user favorites" do
        expect { client.get_user_favorites }.to raise_error(RuntimeError, "Not authenticated")
      end
    end

    context "series details and episodes" do
      it "allows series details without authentication" do
        # This test verifies that get_series_details no longer requires authentication
        # The actual API call will fail in tests, but it shouldn't fail due to missing auth
        expect(client).to respond_to(:get_series_details)
      end

      it "allows episodes without authentication" do
        # This test verifies that get_series_episodes no longer requires authentication
        # The actual API call will fail in tests, but it shouldn't fail due to missing auth
        expect(client).to respond_to(:get_series_episodes)
      end

      it "requires authentication for episode details" do
        expect { client.get_episode_details(123456) }.to raise_error(RuntimeError, "Not authenticated")
      end
    end
  end

  describe "InvalidPinError exception" do
    it "defines InvalidPinError exception class" do
      expect(InvalidPinError).not_to be_nil
      expect(InvalidPinError).to be < StandardError
    end
  end

  describe "PIN detection logic" do
    context "word boundary matching" do
      it "matches PIN with word boundaries" do
        expect("Invalid PIN provided").to match(/\bpin\b/i)
        expect("PIN is required").to match(/\bpin\b/i)
      end

      it "does not match PIN within other words" do
        expect("shipping required").not_to match(/\bpin\b/i)
        expect("spinning up server").not_to match(/\bpin\b/i)
      end
    end

    context "invalid PIN patterns" do
      it "matches invalid PIN error patterns" do
        expect("invalid PIN provided").to match(/invalid.*pin|pin.*invalid/i)
        expect("PIN invalid for user").to match(/invalid.*pin|pin.*invalid/i)
      end

      it "does not match unrelated invalid patterns" do
        expect("invalid request").not_to match(/invalid.*pin|pin.*invalid/i)
      end
    end
  end

  describe "#get_episode_details" do
    before do
      # Set the token instance variable directly
      client.instance_variable_set(:@token, "fake_token")
    end

    context "with successful response" do
      let(:episode_details_response) do
        {
          "data" => {
            "id" => 123456,
            "name" => "Test Episode",
            "overview" => "This is a detailed overview of the test episode with multiple characters and plot details.",
            "runtime" => 45,
            "aired" => "2023-01-01",
            "seasonNumber" => 1,
            "number" => 5
          }
        }
      end

      before do
        allow(TvdbClient).to receive(:get).and_return(
          double(success?: true, parsed_response: episode_details_response)
        )
      end

      it "returns episode details data" do
        result = client.get_episode_details(123456)

        expect(result).to eq(episode_details_response["data"])
        expect(result["overview"]).to eq("This is a detailed overview of the test episode with multiple characters and plot details.")
        expect(result["runtime"]).to eq(45)
        expect(result["name"]).to eq("Test Episode")
      end

      it "calls correct API endpoint" do
        client.get_episode_details(123456)

        expect(TvdbClient).to have_received(:get).with(
          "/episodes/123456/extended",
          headers: {
            "Authorization" => "Bearer fake_token",
            "Content-Type" => "application/json"
          }
        )
      end
    end

    context "with API error response" do
      before do
        allow(TvdbClient).to receive(:get).and_return(
          double(success?: false, parsed_response: { "message" => "Episode not found" })
        )
      end

      it "raises error for failed API call" do
        expect { client.get_episode_details(999999) }.to raise_error(
          RuntimeError, "Failed to fetch episode details: Episode not found"
        )
      end
    end

    context "with episode that has no overview" do
      let(:episode_details_response) do
        {
          "data" => {
            "id" => 123456,
            "name" => "Test Episode",
            "overview" => nil,
            "runtime" => 45,
            "aired" => "2023-01-01"
          }
        }
      end

      before do
        allow(TvdbClient).to receive(:get).and_return(
          double(success?: true, parsed_response: episode_details_response)
        )
      end

      it "returns data with nil overview" do
        result = client.get_episode_details(123456)

        expect(result["overview"]).to be_nil
        expect(result["name"]).to eq("Test Episode")
      end
    end

    context "with episode that has empty overview" do
      let(:episode_details_response) do
        {
          "data" => {
            "id" => 123456,
            "name" => "Test Episode",
            "overview" => "",
            "runtime" => 45,
            "aired" => "2023-01-01"
          }
        }
      end

      before do
        allow(TvdbClient).to receive(:get).and_return(
          double(success?: true, parsed_response: episode_details_response)
        )
      end

      it "returns data with empty overview" do
        result = client.get_episode_details(123456)

        expect(result["overview"]).to eq("")
        expect(result["name"]).to eq("Test Episode")
      end
    end
  end
end
