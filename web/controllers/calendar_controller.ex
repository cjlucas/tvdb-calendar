defmodule TVDBCalendar.CalendarController do
  use TVDBCalendar.Web, :controller

  def index(conn, %{"id" => id}) do
    IO.puts("GOT ID: #{id}")

    case TVDBCalendar.Repo.Store.user_by_id(id) do
      {:ok, %{username: user, days_before: days_before, days_after: days_after}} ->
        now = DateTime.utc_now()

        series =
          TVDBCalendar.Repo.user_favorites(user)
          |> Enum.filter(&TVDBCalendar.Repo.has_series?/1)
          |> Enum.map(&TVDBCalendar.Repo.series_info/1)
          |> Enum.map(fn series ->
            Map.update!(series, :episodes, fn episodes ->
              Enum.filter(episodes, fn ep ->
                # Filter out episodes that aired over 30 days ago
                diff = Timex.diff(ep[:first_aired], now, :days)
                diff > -days_before && diff < days_after
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
