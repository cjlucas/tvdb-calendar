defmodule TVDBCalendar.LoginController do
  use TVDBCalendar.Web, :controller

  def index(conn, _params) do
    conn
    |> render("index.html")
  end

  def create(conn, %{"username" => username, "acct_id" => acct_id}) do
    IO.puts("OMGHERE")

    case find_or_create_user(username, acct_id) do
      {:ok, %{id: id}} ->
        conn
        |> put_session(:uid, id)
        |> put_flash(:info, "Login successful")
        |> redirect(to: "/")
      {:error, reason} ->
        IO.puts("ERRRO")
        conn
        |> put_flash(:error, "Login failed (reason: #{inspect reason})")
        |> redirect(to: "/login")
    end
  end

  def delete(conn, _params) do
    conn
    |> clear_session
    |> redirect(to: "/")
  end
  
  defp find_or_create_user(username, user_key) do
    case TVDBCalendar.Repo.Store.user_by_name(username) do
      {:ok, user} ->
        {:ok, user}
      {:error, :no_user_found} ->
        TVDBCalendar.Repo.add_user(username, user_key)
    end
  end
end