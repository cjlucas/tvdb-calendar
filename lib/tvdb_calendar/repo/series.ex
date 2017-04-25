defmodule TVDBCalendar.Repo.Series do
  use GenServer
  require Logger

  @refresh_interval Application.fetch_env!(:tvdb_calendar, :series_refresh_interval) * 1000

  defmodule State do
    defstruct [:series_id, :airs_time, :runtime, :series_name, :episodes, :next_refresh]

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

  def init(series_id) do
    Logger.metadata([series_id: series_id])

    {:ok, %State{series_id: series_id}, 0}
  end

  def handle_call(:info, _from, state) do
    %{next_refresh: t} = state
    {:reply, Map.take(state, [:series_name, :episodes]), state, timeout(t)}
  end

  def handle_call(:refresh_episodes, _from, state) do
    %{series_id: id, next_refresh: t} = state

    episodes = do_fetch_episodes(id)
    {:reply, :ok, State.put_episodes(state, episodes), timeout(t)}
  end

  def handle_info(:timeout, state) do
    %{series_id: id, series_name: name} = state
    
    Logger.debug("Refreshing series information")

    state =
      try do
        state =
          if is_nil(name) do
            %{series_name: name, airs_time: time, runtime: runtime} = TheTVDB.Series.info(id)
            %{state | series_name: name, airs_time: time, runtime: runtime, episodes: []}
          else
            state
          end

        episodes = do_fetch_episodes(id)
        State.put_episodes(state, episodes)
      rescue
        e ->
          Logger.error("Received error while fetching series info: #{inspect e}")
          state
      end

    {:noreply, %{state | next_refresh: now() + @refresh_interval}, @refresh_interval}
  end

  defp do_fetch_episodes(series_id) do
    TheTVDB.Series.episodes(series_id)
    |> Stream.filter(fn ep ->
      ep.first_aired != nil
    end)
    |> Enum.map(fn ep ->
      %{
        episode_name: ep.episode_name,
        season_num: ep.aired_season,
        episode_num: ep.aired_episode_number,
        first_aired: ep.first_aired,
        overview: ep.overview
      }
    end)
  end

  defp now do
    System.monotonic_time(:millisecond)
  end

  defp timeout(next_refresh) do
    next_refresh - now()
  end

  defp via(series_id) do
    key = {:series, series_id}
    {:via, Registry, {TVDBCalendar.Repo.Registry, key}}
  end
end
