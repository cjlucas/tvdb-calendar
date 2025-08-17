require "rails_helper"

RSpec.describe UserSyncService do
  let(:user) { create(:user) }

  before do
    ENV["TVDB_API_KEY"] = "test_key"
  end

  after do
    ENV.delete("TVDB_API_KEY")
  end

  describe "#initialize" do
    context "with force parameter" do
      it "sets force flag to true when force: true" do
        service = described_class.new(user, force: true)
        expect(service.instance_variable_get(:@force)).to be true
      end

      it "sets force flag to false when force: false" do
        service = described_class.new(user, force: false)
        expect(service.instance_variable_get(:@force)).to be false
      end

      it "defaults force flag to false when not specified" do
        service = described_class.new(user)
        expect(service.instance_variable_get(:@force)).to be false
      end
    end
  end

  describe "#call" do
    let(:mock_client) { instance_double(TvdbClient) }
    let(:mock_series_service) { instance_double(SeriesSyncService) }

    before do
      allow(TvdbClient).to receive(:new).and_return(mock_client)
      allow(SeriesSyncService).to receive(:new).and_return(mock_series_service)
      allow(mock_client).to receive(:authenticate).with(user.pin).and_return(true)
    end

    context "when force is true" do
      let(:service) { described_class.new(user, force: true) }
      let(:series) { create(:series, tvdb_id: 12345, name: "Test Series", last_synced_at: 1.hour.ago) }

      before do
        user.user_series.create!(series: series)
        allow(mock_client).to receive(:get_user_favorites).and_return([ series.tvdb_id ])
      end

      it "syncs recently synced series" do
        expect(mock_series_service).to receive(:sync_episodes_for_series).with(series, anything)
        service.call
      end
    end

    context "when force is false" do
      let(:service) { described_class.new(user, force: false) }
      let(:series) { create(:series, tvdb_id: 12345, name: "Test Series", last_synced_at: 1.hour.ago) }

      before do
        user.user_series.create!(series: series)
        allow(mock_client).to receive(:get_user_favorites).and_return([ series.tvdb_id ])
      end

      it "does not sync recently synced series" do
        expect(mock_series_service).not_to receive(:sync_episodes_for_series)
        service.call
      end
    end

    context "with new series" do
      let(:new_series_id) { 99999 }
      let(:service_without_force) { described_class.new(user, force: false) }
      let(:service_with_force) { described_class.new(user, force: true) }

      before do
        allow(mock_client).to receive(:get_user_favorites).and_return([ new_series_id ])
        allow(mock_client).to receive(:get_series_details).with(new_series_id).and_return({
          "name" => "New Test Series",
          "remoteIds" => []
        })
      end

      it "syncs new series even without force" do
        expect(mock_series_service).to receive(:sync_episodes_for_series).once
        service_without_force.call
      end

      it "syncs new series with force" do
        # Clean up any series that might exist from previous test
        Series.find_by(tvdb_id: new_series_id)&.destroy

        expect(mock_series_service).to receive(:sync_episodes_for_series).once
        service_with_force.call
      end
    end

    context "when API error occurs" do
      let(:service) { described_class.new(user, force: true) }
      let(:series) { create(:series, tvdb_id: 12346, name: "Error Test Series", last_synced_at: 1.hour.ago) }

      before do
        user.user_series.create!(series: series)
        allow(mock_client).to receive(:get_user_favorites).and_raise(StandardError.new("API Error"))
      end

      it "handles error gracefully" do
        expect { service.call }.to raise_error(StandardError, "API Error")
      end
    end

    context "after successful sync" do
      let(:service) { described_class.new(user, force: true) }

      before do
        allow(mock_client).to receive(:get_user_favorites).and_return([])
      end

      it "marks user as synced" do
        expect(user.last_synced_at).to be_nil # Initially nil for new user
        service.call
        user.reload
        expect(user.last_synced_at).to be_present
        expect(user.last_synced_at).to be_within(1.second).of(Time.current)
      end
    end
  end
end
