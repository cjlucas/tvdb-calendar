defmodule TVDBCalendar.Repo do
  def add_user(username, user_key) do
    case TVDBCalendar.Repo.Supervisor.start_user_repo(username, user_key) do
      {:ok, _} ->
        TVDBCalendar.Repo.Store.add_user(username, user_key)
      {:error, :already_started} ->
        {:error, :user_exists}
      {:error, {reason, _}} ->
        {:error, reason}
    end
  end

  def user_favorites(username) do
    TVDBCalendar.Repo.User.favorites(username)
  end

  def has_user?(username) do
    has_key?({:user, username})
  end

  def refresh_user_favorites(username) do
    TVDBCalendar.Repo.User.refresh_favorites(username)
  end

  def add_series(series_id) do
    {:ok, _} = TVDBCalendar.Repo.Supervisor.start_series_repo(series_id)
    :ok
  end

  def series_info(series_id) do
    TVDBCalendar.Repo.Series.info(series_id)
  end

  def has_series?(series_id) do
    has_key?({:series, series_id})
  end

  def refresh_series(series_id) do
    TVDBCalendar.Repo.Series.refresh_episodes(series_id)
  end

  defp has_key?(key) do
    Registry.lookup(TVDBCalendar.Repo.Registry, key) |> length > 0
  end
end
