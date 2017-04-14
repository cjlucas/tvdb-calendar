defmodule TVDBCalendar.PageController do
  use TVDBCalendar.Web, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end
end
