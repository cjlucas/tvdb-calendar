defmodule TVDBCalendar.Mixfile do
  use Mix.Project

  def project do
    [app: :tvdb_calendar,
     version: System.get_env("APP_VERSION") || "0.0.0",
     elixir: "~> 1.2",
     elixirc_paths: elixirc_paths(Mix.env),
     compilers: [:phoenix, :gettext] ++ Mix.compilers,
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps()]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {TVDBCalendar, []},
      extra_applications: [:logger]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "web", "test/support"]
  defp elixirc_paths(_),     do: ["lib", "web"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:phoenix, "~> 1.6"},
      {:phoenix_pubsub, "~> 2.0"},
      {:phoenix_html, "~> 3.0"},
      {:phoenix_live_reload, "~> 1.3", only: :dev},
      {:gettext, "~> 0.11"},
      {:plug_cowboy, "~> 2.5"},
      {:plug, "~> 1.12"},
      {:thetvdb, "~> 1.1"},
      {:timex, "~> 3.0"},
      {:uuid, "~> 1.1"},
      {:exprintf, "~> 0.2.1"},
      {:distillery, "~> 1.3"},
      {:jason, "~> 1.3"}
   ]
  end
end
