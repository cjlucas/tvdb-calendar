defmodule TVDBCalendar.PageController do
  use TVDBCalendar.Web, :controller

  def index(conn, _params) do
    id = get_session(conn, :uid)
    if is_nil(id) do
      redirect conn, to: "/login"
    else
      render conn, "index.html", id: id
    end
  end
end
