defmodule TVDBCalendar.Router do
  use TVDBCalendar.Web, :router

  pipeline :browser do
    plug :accepts, ["html", "ics", "ifb"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", TVDBCalendar do
    pipe_through :browser # Use the default browser stack

    get "/", PageController, :index
    get "/login", LoginController, :index
    post "/login", LoginController, :create
    get "/logout", LoginController, :delete
    get "/calendar/:id", CalendarController, :index

    put "/user", UserController, :update
  end

  # Other scopes may use custom stacks.
  # scope "/api", TVDBCalendar do
  #   pipe_through :api
  # end
end
