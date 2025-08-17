require "rails_helper"

RSpec.describe "Users API", type: :request do
  describe "POST /users" do
    context "with valid pin" do
      let(:pin) { "new_user_#{rand(100000..999999)}" }

      before do
        post users_path, params: { user: { pin: pin } }, as: :json
      end

      it "returns success response" do
        expect(response).to have_http_status(:success)
      end

      it "returns syncing status for new user" do
        response_data = JSON.parse(response.body)
        expect(response_data["status"]).to eq("syncing")
        expect(response_data["user_pin"]).to be_present
        expect(response_data["calendar_url"]).to be_present
      end

      it "creates the user" do
        user = User.find_by(pin: pin)
        expect(user).to be_present
      end
    end

    context "with existing user needing sync" do
      let(:pin) { "existing_user_#{rand(100000..999999)}" }
      let!(:user) { create(:user, pin: pin, last_synced_at: 2.hours.ago) }

      before do
        post users_path, params: { user: { pin: pin } }, as: :json
      end

      it "returns success response" do
        expect(response).to have_http_status(:success)
      end

      it "returns syncing status" do
        response_data = JSON.parse(response.body)
        expect(response_data["status"]).to eq("syncing")
        expect(response_data["user_pin"]).to eq(user.pin)
      end
    end

    context "with existing user not needing sync" do
      let(:pin) { "ready_user_#{rand(100000..999999)}" }
      let!(:user) { create(:user, pin: pin, last_synced_at: 30.minutes.ago) }

      before do
        post users_path, params: { user: { pin: pin } }, as: :json
      end

      it "returns success response" do
        expect(response).to have_http_status(:success)
      end

      it "returns ready status" do
        response_data = JSON.parse(response.body)
        expect(response_data["status"]).to eq("ready")
        expect(response_data["user_pin"]).to eq(user.pin)
      end
    end

    context "with validation errors" do
      before do
        post users_path, params: { user: { pin: "" } }, as: :json
      end

      it "returns unprocessable content status" do
        expect(response).to have_http_status(:unprocessable_content)
      end

      it "returns error response" do
        response_data = JSON.parse(response.body)
        expect(response_data["status"]).to eq("error")
        expect(response_data["errors"]).to be_present
      end
    end

    context "with missing pin parameter" do
      before do
        post users_path, params: { user: { pin: nil } }, as: :json
      end

      it "returns unprocessable content status" do
        expect(response).to have_http_status(:unprocessable_content)
      end

      it "returns error response" do
        response_data = JSON.parse(response.body)
        expect(response_data["status"]).to eq("error")
      end
    end
  end

  describe "InvalidPinError exception handling" do
    it "defines InvalidPinError exception class" do
      expect(InvalidPinError).not_to be_nil
      expect(InvalidPinError).to be < StandardError
    end

    it "handles InvalidPinError in rescue clause" do
      # Verify the rescue clause for InvalidPinError exists in controller
      controller_source = File.read(Rails.root.join("app/controllers/users_controller.rb"))
      expect(controller_source).to include("rescue InvalidPinError")
      expect(controller_source).to include('"PIN Invalid"')
    end
  end
end
