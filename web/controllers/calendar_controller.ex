defmodule TVDBCalendar.CalendarController do
  use TVDBCalendar.Web, :controller

  def index(conn, %{"id" => id}) do
    IO.puts("GOT ID: #{id}")

    case TVDBCalendar.Repo.Store.lookup_user(id) do
      {:ok, %{username: user}} ->
        now = DateTime.utc_now()

        series =
          TVDBCalendar.Repo.user_favorites(user)
          |> Enum.map(&TVDBCalendar.Repo.series_info/1)
          |> Enum.map(fn series ->
            series
            |> Enum.into(%{})
            |> Map.update!(:episodes, fn episodes ->
              Enum.filter(episodes, fn ep ->
                # Filter out episodes that aired over 30 days ago
                Timex.diff(ep[:first_aired], now, :days) > -30
              end)
            end)
          end)
          |> Enum.filter(fn series ->
            length(series[:episodes]) > 0
          end)

        render conn, "index.ics", series: series
      {:error, :no_user_found} ->
        send_resp(conn, 404, "no user found")
    end
  end

  def index(conn, _) do
    send_resp(conn, 400, "missing paramters")
  end
end