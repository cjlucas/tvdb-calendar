defmodule TVDBCalendar.CalendarController do
  use TVDBCalendar.Web, :controller

  def index(conn, %{"id" => id}) do
    IO.puts("GOT ID: #{id}")

    case TVDBCalendar.Repo.Store.lookup_user(id) do
      {:ok, %{username: user}} ->
        data = TVDBCalendar.Repo.user_favorites(user)
               |> Enum.map(&TVDBCalendar.Repo.series_info/1)

        render conn, "index.json", data
      {:error, :no_user_found} ->
          send_resp(conn, 404, "no user found")
    end
  end

  def index(conn, _) do
    send_resp(conn, 400, "missing paramters")
  end
end
