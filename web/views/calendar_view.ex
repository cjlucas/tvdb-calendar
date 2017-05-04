defmodule TVDBCalendar.CalendarView do
  use TVDBCalendar.Web, :view
  import ExPrintf

  @title_fmt parse_printf("%s (%02dx%02d)")

  def render("index.ics", %{series: series}) do
    series
    |> Enum.flat_map(fn series ->
      Enum.map(series[:episodes], &Map.put_new(&1, :series_name, series[:series_name]))
    end)
    |> Enum.map(fn ep ->
      args = [
        Map.get(ep, :episode_name) || "TBA",
        Map.get(ep, :season_num) || 0,
        Map.get(ep, :episode_num) || 0
      ]

      title = :io_lib.format(@title_fmt, args) |> IO.chardata_to_string
      Map.put(ep, :title, title)
    end)
    |> Enum.map(fn ep ->
      %ICS.Event{
        summary: ep.series_name,
        location: ep.title,
        dtstart: ep.start_time,
        dtend: ep.end_time,
        description: ep.overview
      }
    end)
    |> ICS.encode
  end
end
