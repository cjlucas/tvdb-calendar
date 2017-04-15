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
      %ICalendar.Event{
        summary: ep.series_name,
        location: ep.title,
        dtstart: Timex.to_erl(ep.start_time),
        dtend: Timex.to_erl(ep.end_time),
        description: ep.overview
      }
    end)
    |> wrap_events
    |> ICalendar.to_ics
  end

  defp wrap_events(events), do: %ICalendar{events: events}
end
