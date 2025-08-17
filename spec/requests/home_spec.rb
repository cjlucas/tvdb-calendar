require "rails_helper"

RSpec.describe "Home", type: :request do
  describe "GET /" do
    before do
      get root_path
    end

    it "gets index successfully" do
      expect(response).to have_http_status(:success)
    end

    it "renders main page content" do
      expect(response.body).to include("TVDB Calendar Generator")
      expect(response.body).to include("<form")
      expect(response.body).to include('name="user[pin]"')
    end

    it "renders form for user input" do
      expect(response.body).to include('name="user[pin]"')
      expect(response.body).to include('placeholder')
      expect(response.body).to include('type="submit"')
    end
  end
end
