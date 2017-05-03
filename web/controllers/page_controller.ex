defmodule TVDBCalendar.PageController do
  use TVDBCalendar.Web, :controller

  def index(conn, _params) do
    id = get_session(conn, :uid)

    before_opts = [
      {"one month ago", 31},
      {"one week ago", 7},
      {"today", 0}
    ]
    after_opts = [
      {"one week from now", 7},
      {"one month from now", 31},
      {"forever", :infinity}
    ]

    if is_nil(id) do
      redirect conn, to: "/login"
    else
      render conn, "index.html", id: id, before_opts: before_opts, after_opts: after_opts
    end
  end
end
