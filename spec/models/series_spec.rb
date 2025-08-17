require "rails_helper"

RSpec.describe Series, type: :model do
  let(:user) { create(:user) }
  let(:tvdb_id) { rand(100000..999999) }
  let(:series) { build(:series, tvdb_id: tvdb_id) }

  describe "validations" do
    it "is valid with valid attributes" do
      expect(series).to be_valid
    end

    it "requires tvdb_id" do
      series.tvdb_id = nil
      expect(series).not_to be_valid
      expect(series.errors[:tvdb_id]).to include("can't be blank")
    end

    it "requires name" do
      series.name = nil
      expect(series).not_to be_valid
      expect(series.errors[:name]).to include("can't be blank")
    end

    it "requires unique tvdb_id globally" do
      series.save!
      duplicate_series = build(:series, tvdb_id: tvdb_id, name: "Another Series")
      expect(duplicate_series).not_to be_valid
      expect(duplicate_series.errors[:tvdb_id]).to include("has already been taken")
    end

    it "does not allow same tvdb_id for different series" do
      series.save!
      other_series = build(:series, tvdb_id: tvdb_id, name: "Same TVDB ID Different Series")
      expect(other_series).not_to be_valid
    end
  end

  describe "associations" do
    it { is_expected.to have_many(:users).through(:user_series) }
    it { is_expected.to have_many(:user_series) }
    it { is_expected.to have_many(:episodes) }

    it "allows multiple users to have same series" do
      series.save!
      user.user_series.create!(series: series)

      other_user = create(:user)
      other_user.user_series.create!(series: series)

      expect(series.users).to include(user)
      expect(series.users).to include(other_user)
      expect(series.users.count).to eq(2)
    end
  end

  describe "#imdb_url" do
    context "with imdb_id" do
      it "returns correct URL" do
        expected_url = "https://www.imdb.com/title/tt1234567/"
        expect(series.imdb_url).to eq(expected_url)
      end
    end

    context "without imdb_id" do
      it "returns nil" do
        series.imdb_id = nil
        expect(series.imdb_url).to be_nil
      end
    end

    context "with blank imdb_id" do
      it "returns nil" do
        series.imdb_id = ""
        expect(series.imdb_url).to be_nil
      end
    end
  end

  describe "#needs_sync?" do
    context "when last_synced_at is nil" do
      it "returns true" do
        series.last_synced_at = nil
        expect(series.needs_sync?).to be true
      end
    end

    context "when last_synced_at is older than 12 hours" do
      it "returns true" do
        series.last_synced_at = 13.hours.ago
        expect(series.needs_sync?).to be true
      end
    end

    context "when last_synced_at is within 12 hours" do
      it "returns false" do
        series.last_synced_at = 11.hours.ago
        expect(series.needs_sync?).to be false
      end
    end
  end

  describe "#mark_as_synced!" do
    it "updates last_synced_at to current time" do
      series.save!
      freeze_time = Time.current

      travel_to freeze_time do
        series.mark_as_synced!
        expect(series.reload.last_synced_at.to_f).to be_within(1.0).of(freeze_time.to_f)
      end
    end
  end
end
