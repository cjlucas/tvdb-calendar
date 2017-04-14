defmodule TVDBCalendar.Repo.Series do
  use GenServer

  defmodule State do
    defstruct [:series_id, :airs_time, :runtime, :series_name, :episodes]

    def put_episodes(state, episodes) do
      %{airs_time: airs_time, runtime: runtime} = state

      episodes = Enum.map(episodes, fn ep ->
        {:ok, start_time} = NaiveDateTime.new(ep.first_aired, airs_time)

        ep
        |> Map.put_new(:start_time, start_time)
        |> Map.put_new(:end_time, NaiveDateTime.add(start_time, runtime * 60, :second))
      end)

      %{state | episodes: episodes}
    end
  end

  def start_link(series_id) do
    GenServer.start_link(__MODULE__, series_id, name: via(series_id))
  end

  def info(series_id) do
    via(series_id) |> GenServer.call(:info)
  end

  def refresh_episodes(series_id) do
    via(series_id) |> GenServer.call(:refresh_episodes)
  end

  def stop(series_id) do
    via(series_id) |> GenServer.stop
  end

  def init(series_id) do
    %{series_name: name, airs_time: time, runtime: runtime} = TheTVDB.Series.info(series_id)

    state = %State{
      series_id: series_id,
      airs_time: parse_time(time),
      series_name: name,
      runtime: String.to_integer(runtime),
      episodes: []
    }

    {:ok, state, 0}
  end

  def handle_call(:info, _from, state) do
    {:reply, Map.take(state, [:series_name, :episodes]), state}
  end

  def handle_call(:refresh_episodes, _from, state) do
    %{series_id: id} = state

    episodes = do_fetch_episodes(id)
    {:reply, :ok, State.put_episodes(state, episodes)}
  end

  def handle_info(:timeout, state) do
    %{series_id: id} = state

    episodes = do_fetch_episodes(id)
    {:noreply, State.put_episodes(state, episodes)}
  end

  defp do_fetch_episodes(series_id) do
    TheTVDB.Series.episodes(series_id)
    |> Stream.filter(fn ep ->
      ep.first_aired != ""
    end)
    |> Enum.map(fn ep ->
      %{
        season_num: ep.aired_season,
        episode_num: ep.aired_episode_number,
        first_aired: Timex.parse!(ep.first_aired, "%Y-%m-%d", :strftime) |> NaiveDateTime.to_date,
        overview: ep.overview
      }
    end)
  end

  defp parse_time(time) do
    formats = ["%l:%M %p", "%H:%M", "%k:%M"]
    parse_time(time, formats)
  end

  defp parse_time(_time, []), do: ~T[00:00:00]
  defp parse_time(time, [fmt | rest]) do
    case Timex.parse(time, fmt, :strftime) do
      {:ok, t}    ->
        NaiveDateTime.to_time(t)
      {:error, _} ->
        parse_time(time, rest)
    end
  end

  defp via(series_id) do
    key = {:series, series_id}
    {:via, Registry, {TVDBCalendar.Repo.Registry, key}}
  end
end
