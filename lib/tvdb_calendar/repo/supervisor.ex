defmodule TVDBCalendar.Repo.Supervisor do
  use Supervisor
  
  def start_link do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def start_user_repo(username, user_key) do
    opts = [id: {:user, username}, restart: :transient]
    child = worker(TVDBCalendar.Repo.User, [username, user_key], opts)
    Supervisor.start_child(__MODULE__, child)
  end
  
  def start_series_repo(series_id) do
    opts = [id: {:series, series_id}, restart: :transient]
    child = worker(TVDBCalendar.Repo.Series, [series_id], opts)
    Supervisor.start_child(__MODULE__, child)
  end

  def init(:ok) do
    children = [
      supervisor(Registry, [:unique, TVDBCalendar.Repo.Registry]),
      worker(TVDBCalendar.Repo.Manager, []),
      worker(TVDBCalendar.Repo.Store, [])
    ]
    ret = supervise(children, strategy: :one_for_one)


    ret
  end
end
