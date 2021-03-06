# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :tvdb_calendar,
  namespace: TVDBCalendar

# Configures the endpoint
config :tvdb_calendar, TVDBCalendar.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "0ONsm5OBF6JZcur42Rr2B/fQ1iXGmgegdWf9Zk4PcsmmvjzsPcJ4CrmQXlFLmIme",
  render_errors: [view: TVDBCalendar.ErrorView, accepts: ~w(html json)],
  pubsub: [name: TVDBCalendar.PubSub,
           adapter: Phoenix.PubSub.PG2]

config :tvdb_calendar,
  series_refresh_interval: 3600 * 3,
  user_refresh_interval: 3600

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id, :username, :series_id]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
