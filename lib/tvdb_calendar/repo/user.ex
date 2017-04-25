defmodule TVDBCalendar.Repo.User do
  use GenServer
  require Logger

  @api_key "893D74B715CB7B99"

  @refresh_interval Application.fetch_env!(:tvdb_calendar, :user_refresh_interval) * 1000

  defmodule State do
    defstruct [:username, :favorites, :next_refresh]
  end

  def start_link(username, user_key) do
    GenServer.start_link(__MODULE__, {username, user_key}, name: via(username))
  end

  def favorites(username) do
    via(username) |> GenServer.call(:favorites)
  end

  def refresh_favorites(username) do
    via(username) |> GenServer.call(:refresh_favorites)
  end

  def init({username, user_key}) do
    Logger.metadata([username: username])

    case TheTVDB.authenticate(@api_key, username, user_key) do
      :ok ->
        {:ok, %State{username: username, favorites: []}, 0}
      {:error, reason} ->
        {:stop, reason}
    end
  end

  def handle_call(:favorites, _from, state) do
    %{next_refresh: t} = state
    {:reply, Map.get(state, :favorites, []), state, timeout(t)}
  end

  def handle_call(:refresh_favorites, _from, state) do
    %{username: user, next_refresh: t} = state

    favorites = TheTVDB.User.favorites(user)
    {:reply, :ok, %{state | favorites: favorites}, timeout(t)}
  end

  def handle_info(:timeout, state) do
    %{username: user, favorites: prev_favs} = state

    Logger.debug("Refreshing user favorites")

    favorites =
      try do
        TheTVDB.User.favorites(user)
      rescue
        e ->
          Logger.error("Failed to fetch user favorites: #{inspect e}")
          prev_favs
      end

    :ok = TVDBCalendar.Repo.Manager.user_refreshed_favorites(prev_favs, favorites)
    {:noreply, %{state | favorites: favorites, next_refresh: now() + @refresh_interval}, @refresh_interval}
  end

  def terminate(_reason, state) do
    %{favorites: favorites} = state
    :ok = TVDBCalendar.Repo.Manager.user_removed(favorites)
  end

  defp now do
    System.monotonic_time(:millisecond)
  end

  defp timeout(next_refresh) do
    next_refresh - now()
  end

  defp via(username) do
    key = {:user, username}
    {:via, Registry, {TVDBCalendar.Repo.Registry, key}}
  end
end
