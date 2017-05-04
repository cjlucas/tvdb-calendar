defmodule TVDBCalendar do
  use Application

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec

    # Define workers and child supervisors to be supervised
    children = [
      # Start the endpoint when the application starts
      supervisor(TVDBCalendar.Endpoint, []),
      supervisor(TVDBCalendar.Repo.Supervisor, [])
    ]

    opts = [strategy: :one_for_one, name: TVDBCalendar.Supervisor]
    ret = Supervisor.start_link(children, opts)

    #TVDBCalendar.Repo.add_user("cjlucas", "77274F4783EE9EE1")

    ret
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    TVDBCalendar.Endpoint.config_change(changed, removed)
    :ok
  end
end
