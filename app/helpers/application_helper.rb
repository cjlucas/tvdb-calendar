module ApplicationHelper
  def app_version
    ENV["APP_VERSION"]
  end
end
