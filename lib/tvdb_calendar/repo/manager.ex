defmodule TVDBCalendar.Repo.Manager do
  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    {:ok, Map.new, 0}
  end

  def user_refreshed_favorites(prev, curr) do
    GenServer.cast(__MODULE__, {:user_refreshed_favorites, prev, curr})
  end

  def user_removed(favorites) do
    user_refreshed_favorites(favorites, [])
  end

  def handle_info(:timeout, state) do
    TVDBCalendar.Repo.Store.all_users()
    |> Enum.each(fn %{username: username, key: key} ->
      TVDBCalendar.Repo.Supervisor.start_user_repo(username, key)
    end)

    {:noreply, state}
  end

  def handle_cast({:user_refreshed_favorites, prev, curr}, state) do
    prev = MapSet.new(prev)
    curr = MapSet.new(curr)

    added   = MapSet.difference(curr, prev)
    removed = MapSet.union(curr, prev) |> MapSet.difference(curr)

    state = Enum.reduce(added, state, fn id, acc ->
      Map.update(acc, id, 1, &(&1 + 1))
    end)
    state = Enum.reduce(removed, state, fn id, acc ->
      Map.update(acc, id, 1, &(&1 - 1))
    end)

    Enum.each(state, fn {id, cnt} ->
      cond do
        cnt == 1 && !TVDBCalendar.Repo.has_series?(id) ->
          {:ok, _} = TVDBCalendar.Repo.Supervisor.start_series_repo(id)
        cnt == 0 && TVDBCalendar.Repo.has_series?(id) ->
          :ok = TVDBCalendar.Repo.Supervisor.terminate_series_repo(id)
        true ->
          nil
      end
    end)

    {:noreply, state}
  end
end
