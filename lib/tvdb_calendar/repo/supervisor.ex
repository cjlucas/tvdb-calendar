defmodule TVDBCalendar.Repo.Supervisor do
  use Supervisor
  require Logger

  def start_link do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def start_user_repo(username, user_key) do
    opts = [id: {:user, username}, restart: :transient]
    child = worker(TVDBCalendar.Repo.User, [username, user_key], opts)

    Logger.debug("Starting Repo.User (username: #{username})")
    Supervisor.start_child(__MODULE__, child)
  end

  def start_series_repo(series_id) do
    opts = [id: series_repo_child_id(series_id), restart: :transient]
    child = worker(TVDBCalendar.Repo.Series, [series_id], opts)

    Logger.debug("Starting Repo.Series (id: #{series_id})")
    Supervisor.start_child(__MODULE__, child)
  end

  def terminate_series_repo(series_id) do
    id = series_repo_child_id(series_id)
    with :ok <- Supervisor.terminate_child(__MODULE__, id),
        :ok  <- Supervisor.delete_child(__MODULE__, id) do
        :ok
    end
  end

  def init(:ok) do
    children = [
      supervisor(Registry, [:unique, TVDBCalendar.Repo.Registry]),
      worker(TVDBCalendar.Repo.Store, []),
      worker(TVDBCalendar.Repo.Manager, [])
    ]
    supervise(children, strategy: :one_for_one)
  end

  defp series_repo_child_id(series_id), do: {:series, series_id}
end
