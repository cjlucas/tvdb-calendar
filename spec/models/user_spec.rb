require "rails_helper"

RSpec.describe User, type: :model do
  let(:user) { build(:user) }

  describe "validations" do
    it "is valid with valid attributes" do
      expect(user).to be_valid
    end

    it "requires a pin" do
      user.pin = nil
      expect(user).not_to be_valid
      expect(user.errors[:pin]).to include("can't be blank")
    end

    it "requires unique pin" do
      pin = "unique_test_#{rand(100000..999999)}"
      existing_user = create(:user, pin: pin)
      duplicate_user = build(:user, pin: pin)
      expect(duplicate_user).not_to be_valid
      expect(duplicate_user.errors[:pin]).to include("has already been taken")
    end
  end

  describe "associations" do
    it { is_expected.to have_many(:series) }
    it { is_expected.to have_many(:episodes).through(:series) }
  end

  describe "#needs_sync?" do
    context "for new user" do
      let(:user) { build(:user, :needs_sync) }

      it "returns true" do
        expect(user.needs_sync?).to be true
      end
    end

    context "for user not synced in over an hour" do
      let(:user) { create(:user, :stale_sync) }

      it "returns true" do
        expect(user.needs_sync?).to be true
      end
    end

    context "for recently synced user" do
      let(:user) { create(:user, :recently_synced) }

      it "returns false" do
        expect(user.needs_sync?).to be false
      end
    end
  end

  describe "#mark_as_synced!" do
    let(:user) { create(:user) }

    it "updates last_synced_at" do
      before_time = Time.current

      user.mark_as_synced!

      expect(user.reload.last_synced_at).to be >= before_time
      expect(user.reload.last_synced_at).to be <= Time.current
    end
  end
end
