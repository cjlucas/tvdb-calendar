class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  protected

  def authenticate_admin!
    return true if Rails.env.development?

    authenticate_or_request_with_http_basic("Admin") do |username, password|
      username == ENV["ADMIN_USERNAME"] && password == ENV["ADMIN_PASSWORD"]
    end
  end

  def current_admin
    return "admin" if Rails.env.development?
    return "admin" if authenticate_admin!
    nil
  end
end
