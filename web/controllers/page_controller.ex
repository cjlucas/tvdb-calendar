defmodule TVDBCalendar.PageController do
  use TVDBCalendar.Web, :controller

  def index(conn, _params) do
    id = get_session(conn, :uid)
    
    case TVDBCalendar.Repo.Store.user_by_id(id) do
      {:error, _} ->
        redirect conn, to: "/login"
      {:ok, %{settings: settings}} ->
        render conn, "index.html", id: id, settings: settings
    end
  end
end
